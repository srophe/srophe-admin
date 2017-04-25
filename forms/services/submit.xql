xquery version "3.1";
(:~
 : Submit xforms generated data
 : @param $type options view (view xml in new window), download (download xml without saving), save (save to db, only available to logged in users)
:)
import module namespace global="http://syriaca.org/global" at "../../modules/lib/global.xqm";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare option output:method "xml";
declare option output:media-type "text/xml";


(: Parse xml strings in text nodes into xml elements :)
declare function local:parse-text($nodes as node()*) as item()* {
    for $node in $nodes
    return
    typeswitch($node)
        case text() return 
            parse-xml-fragment($node)
        default return local:passthru($node)
};

declare function local:passthru($node as node()*) as item()* {
    element {name($node)} {($node/@*, local:parse-text($node/node()))}
};
let $temp := doc('/db/apps/srophe-admin/data/persons/tei/2986.xml')
let $results := request:get-data()
let $id := replace($results/descendant::tei:idno[1],'/tei','')      
let $file-name := concat(tokenize($id,'/')[last()], '.xml')
let $date := fn:current-date() 
return 
    if(request:get-parameter('type', '') = 'view') then
        (response:set-header("Content-type", 'text/xml'),
        serialize($results, 
        <output:serialization-parameters>
            <output:method>xml</output:method>
            <output:media-type>text/xml</output:media-type>
        </output:serialization-parameters>))
    else if(request:get-parameter('type', '') = 'download') then
       (response:set-header("Content-Disposition", fn:concat("attachment; filename=", $file-name)),$results)
    else if(request:get-parameter('type', '') = 'save') then 
        let $data-root := (:$global:data-root:) '/db/apps/srophe-admin/data'
        let $collection :=
            if(contains($id,'/place/')) then concat($data-root,'/places/tei')
            else if(contains($id,'/person')) then concat($data-root,'/persons/tei')
            else if(contains($id,'/bibl')) then concat($data-root,'/bibl/tei')
            else if(contains($id,'/manuscript')) then concat($data-root,'/manuscripts/tei')
            else if(contains($id,'/work')) then concat($data-root,'/works/tei')
            else ()
        let $path-name := 
            if(contains($id, '/place')) then concat($data-root, '/places/tei/', $file-name)
            else if(contains($id, '/person')) then concat($data-root, '/persons/tei/', $file-name)
            else if(contains($id, '/bibl')) then concat($data-root, '/bibl/tei/', $file-name)
            else if(contains($id,'/manuscript')) then concat($data-root, '/manuscripts/tei/', $file-name)
            else if(contains($id,'/work')) then concat($data-root, '/works/tei/', $file-name)
            else ()
        return             
            if($collection != '' and $path-name != '') then
                try {
                    <data code="200">
                        <message>New record saved: {(xmldb:login("/db", "admin", ""), xmldb:store($collection, $file-name, $results))}</message>
                    </data>
                } catch * {
                    <data code="500">
                        <message>Error saving data</message>
                    </data>            
                }       
            else 
                <data code="500">
                   <message>Error building path id={$id} Path: {$path-name} Collection: {$collection}</message>
                </data> 
    else 
        <data code="500">
            <message>General Error</message>
        </data>
    (:
        <data code="500">
            <message path="{$path-name}">Caught error {$err:code}: {$err:description}</message>
        </data>
        :)