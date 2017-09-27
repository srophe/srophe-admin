xquery version "3.0";
(:~
 : Perseids authorization and submission
 : @dependency oauth.xql
 : @dependency perseids.xml with oauth variables supplied   
:)

import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace http="http://expath.org/ns/http-client";
declare namespace httpclient="http://exist-db.org/xquery/httpclient";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace json="http://www.json.org";
declare option exist:serialize "method=html5 media-type=text/html omit-xml-declaration=yes indent=yes";

(: Perseids configuration file, stores passwords etc. :)
declare variable $perseids-config {if(exists(doc(concat($global:app-root,'/perseids.xml')))) then doc(concat($global:app-root,'/perseids.xml')) else ()}
(: Record ID :)
declare variable $id {request:get-parameter('id', '')};

(:~ 
 : Submit record to Perseids endpoint with authorization code
 : @param $rec-id 
 : @param $type record type, to make sure it gets submitted to the correct board
 : @param $url
 : @param $method
 : @param $access_token
:) 
declare function local:submit-to-sosl($rec-id as xs:string*, $type as xs:string*, $url as xs:string?, $method as xs:string?, $access_token as xs:string?){
let $xmlitem := 
    if($type != '') then 
        if($perseids-config//perseids-board) then 
            string($perseids-config//perseids-board[@record-type = $type]/@xmlitem-type)
        else <message>No board Perseids specified</message>
    else <message>No board Perseids specified, no xml type set</message>       
let $community-name :=
    if($type != '') then 
        if($perseids-config//perseids-board) then 
            string($perseids-config//perseids-board[@record-type = $type]/@community-name)
        else <message>No board Perseids specified</message>
    else <message>No board Perseids specified, no xml type set</message>   
let $url := concat($url, '/',$xmlitem)    
let $submission := 
    http:send-request(<http:request href="{$url}" method="{$method}">
        <http:header name="Authorization" value="{concat('Bearer ',$access_token)}"/>
        <http:header name="Content-Type" value="application/xml"/>
        <http:header name="Accept" value="application/json,application/xml"/>
        {if($rec-id) then <http:body media-type="application/xml">{local:build-submission-properties($rec-id)}</http:body> else ()}
    </http:request>)
return 
    if($submission[1]/@status = 200) then 
        let $response := util:base64-decode($submission[2])
        let $publication := tokenize($response,',')[4]
        let $pub-id := 
            if(starts-with($publication,'"publication"')) then normalize-space(substring-after($publication, ':'))
            else ()    
        let $update-pub := 
                    xqjson:serialize-json(
                        <pair name="object" type="object">
                            <pair name="community_name" type="string">{$community-name}</pair>
                        </pair>)
        let $put := 
             http:send-request(
             <http:request href="https://sosol.perseids.org/sosol/api/v1/publications/{$pub-id}" method="put">
                 <http:header name="Authorization" value="{concat('Bearer ',$access_token)}"/>
                 <http:header name="Content-Type" value="application/json"/>
                 <http:header name="Accept" value="application/json"/>
                 <http:body media-type="application/json" method="text">{$update-pub}</http:body>
             </http:request>)
        return 
            if($put[1]/@status = 200) then 
                let $rb := 
                    http:send-request(
                       <http:request href="https://sosol.perseids.org/sosol/api/v1/publications/{$pub-id}/submit" method="post">
                           <http:header name="Authorization" value="{concat('Bearer ',$access_token)}"/>
                           <http:header name="Content-Type" value="application/x-www-form-urlencoded"/>
                           <http:header name="Accept" value="application/x-www-form-urlencoded"/>
                           <http:body media-type="application/x-www-form-urlencoded" method="text">comment=Submit to Boards</http:body>
                       </http:request>)
                return        
                if($rb[1]/@status = 200) then                
                    <span>Record sucessfully submitted. View it on <a href="http://sosol.perseids.org/sosol/user/user_dashboard">Perseids</a></span>
                else util:base64-decode($rb[2])
            else ('Failed submission: ', string($put[1]/@status), xqjson:parse-json(util:base64-decode($put[2])))
    else ('Failed submission: ', string($submission[1]/@status), xqjson:parse-json(util:base64-decode($submission[2])))
};

(: Buld xml submission, currently supports one record at a time, will need to check with bridget about bulk submission. :)
declare function local:build-submission-properties($rec-id as xs:string?){
    for $rec in collection($global:data-root)//tei:idno[@type='URI'][. = $rec-id]/ancestor::tei:TEI
    return $rec/root()
};
        
<html lang="en">
  <head>
    <meta charset="utf-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/> 
    <title>Perseids submission</title>
    <link rel="stylesheet" type="text/css" href="$main-module/resources/css/bootstrap.min.css" />
    <link rel="stylesheet" type="text/css" href="$main-module/resources/css/main.css" />
  </head>
  <body>
   <div class="container" style="padding:5em 2em;">
    <div class="jumbotron">
        <h3>Submit {$id} to Perseids</h3>
        <div>
            {
            let $authorization_code := session:get-attribute('sosol.code')
            let $access_token := session:get-attribute('sosol.access_token')
            (: Syriaca.org submits data to different boards based on which collection, data type, they belong to. :)
            let $type := 
                if(contains($global:base-uri,'http://syriaca.org/')) then 
                    substring-before(substring-after($id,'http://syriaca.org/'), '/') 
                else ()
            return
                if($access_token != '') then 
                   <div>
                        <p class="small">Submitting record...</p>
                        <p>
                        {local:submit-to-sosl($id,$type,'http://sosol.perseids.org/sosol/api/v1/xmlitems','post',$access_token)}
                        </p>
                    </div>
                else 
                    <div>
                        <p>You are not authenticated! Please login to Perseids:</p>
                        <a href="sosol.xql" class="btn btn-lg btn-primary">Login to Perseids</a>
                    </div>  
            }
        </div>
    </div>
    </div>
    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script type="text/javascript" src="$main-module/resources/js/bootstrap.min.js"></script>
  </body>
</html>