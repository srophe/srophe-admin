xquery version "3.0";
(:~
 : Post processing of records finalized by Persieds
 : @dependency perseids.xml with oauth variables supplied 
:)

import module namespace updates="http://syriaca.org/updates" at "updates.xqm";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace http="http://expath.org/ns/http-client";
declare namespace httpclient="http://exist-db.org/xquery/httpclient";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace json="http://www.json.org";

(: Persieds configuration file, stores passwords etc. :)
declare variable $persieds-config {if(exists(doc(concat($global:app-root,'/persieds.xml')))) then doc(concat($global:app-root,'/persieds.xml')) else ()}

(: API key: store as environmental variable or in persieds.xml: 5d51aff870b383c7e6b16e0bc073ade5 :)
declare variable $api-key {$persieds-config//api-key/text()};

(:~
 : Run updates on submitted record
 :)
declare function local:do-updates($rec){
    let $id := $rec//tei:publicationStmt/tei:idno[@type='URI']
    let $get-rec := collection($global:data-root)//tei:idno[@type='URI'][text() = $id]
    let $db-rec := root($get-rec)  
    let $record-path := document-uri($db-rec)
    let $name := tokenize($record-path,'/')[last()]
    let $collection-uri := substring-before($record-path,$name)
    let $save-new := 
        if($get-rec != '') then
            try {
                if(xmldb:collection-available($collection-uri)) then 
                    (response:set-status-code( 200 ),
                    <response status="okay">
                        <message>{xmldb:store($collection-uri, xmldb:encode-uri($name), root($rec))}</message>
                    </response>)
                else
                    (response:set-status-code( 404 ),
                    <response status="okay">
                        <message>Failed to update resource, resource not found</message>
                    </response>)  
            } catch * {
                (response:set-status-code( 401 ),
                <response status="fail">
                    <message>Failed to save resource {xs:anyURI(concat($collection-uri,$name))}: {concat($err:code, ": ", $err:description)}</message>
                </response>)
            }         
        else
            (response:set-status-code( 401 ),
                <response status="fail">
                    <message>Bad record id.</message>
                </response>)
    let $update := 
        let $db-rec := root(collection($global:data-root)//tei:idno[@type='URI'][text() = $id])
        return 
            try {
                updates:update-rec($db-rec)
            } catch * {
                (response:set-status-code( 401 ),
                <response status="fail">
                    <message>Failed to update resource {xs:anyURI(concat($collection-uri,$name))}: {concat($err:code, ": ", $err:description)}</message>
                </response>)}            
    return 
        if($save-new/@status='okay') then 
            if($update/@status='okay') then
                (response:set-status-code( 200 ),
                <response status="okay">
                    <message>Update resource {xs:anyURI(concat($collection-uri,$name))}</message>
                    <record>
                        {$db-rec}
                    </record>
                </response>)
            else $update
        else $save-new
};

let $rec := request:get-data()
return
    if(not(empty($rec))) then 
        if(request:get-header('apikey') = $api-key) then 
            local:do-updates($rec)
        else 
           (response:set-status-code( 401 ),
            <response status="fail">
                <message>Unauthorized request. </message>
            </response>)           
    else 
        (response:set-status-code( 400 ),
        <response status="fail">
            <message>No POST data was received</message>
        </response>)