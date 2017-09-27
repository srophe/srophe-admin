xquery version "3.0";

(:~
 : Perseids OAuth and submission
 : Used to submit records to Perseids for review and publication. 
 : @dependency perseids.xml with oauth variables supplied: 
    <oauth_config>
        <provider name="sosl">
            <id></id>
            <secret></secret>
            <access_token_url></access_token_url>
            <authorize_url></authorize_url>
            <redirect_url></redirect_url>
        </provider>
    </oauth_config> 
:)
module namespace oauth="http://syriaca.org/oauth";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace http="http://expath.org/ns/http-client";
declare namespace httpclient="http://exist-db.org/xquery/httpclient";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace json="http://www.json.org";
declare option exist:serialize "method=xml media-type=text/xml indent=yes";

(: Perseids configuration file, stores passwords etc. :)
declare variable $oauth:perseids-config {if(exists(doc(concat($global:app-root,'/perseids.xml')))) then doc(concat($global:app-root,'/perseids.xml')) else ()}
(: oauth vars :)
declare variable $oauth:code {request:get-parameter('code', '')};
declare variable $oauth:id {request:get-parameter('id', '')};
(: not currently used but if we need to do mulitple providers (sosl and github for example) this will be useful :)
declare variable $oauth:provider {request:get-parameter('provider', '')};

(: Build provider profile :)
declare function oauth:provider-config(){
    $oauth:persieds-config//oauth_config
};

declare function oauth:authenticate(){
let $auth_provider  := oauth:provider-config()/provider
let $client_id      := $auth_provider/id/text()
let $client_secret  := $auth_provider/secret/text()
let $redirect_url   := $auth_provider/redirect_url/text()
let $scope          := 'write'
let $auth-url       := concat(oauth:provider-config()//authorize_url/text(),
                        "?response_type=code","&amp;redirect_uri=",$redirect_url,
                        "&amp;realm=your-realms&amp;client_id=",$client_id, "&amp;scope=",$scope)   
                        
(: Get authorization token :)                                     
let $get-token_params := fn:concat("client_id=",$client_id,
                                   "&amp;code=", $oauth:code,
                                   "&amp;grant_type=authorization_code",
                                   "&amp;redirect_uri=", encode-for-uri($redirect_url),
                                   "&amp;client_secret=",$client_secret)
                         
return 
    if($oauth:code = '') then 
        response:redirect-to($auth-url)
    else 
        let $access_token_response := 
            (http:send-request(
            <http:request href="{$auth_provider/access_token_url}" method="post">
                <http:body media-type="application/x-www-form-urlencoded">{$get-token_params}</http:body>
            </http:request>), session:set-attribute("sosol.code", $oauth:code))
        return 
            if($access_token_response[1]/@status = 200) then 
                let $access_token := xqjson:parse-json(util:base64-decode($access_token_response[2]))//*[@name = 'access_token']/text()
                return session:set-attribute("sosol.access_token", $access_token)
            else util:base64-decode($access_token_response[2])
};            