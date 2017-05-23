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

declare variable $editor := 
    if(request:get-attribute(concat($global:login-domain, '.user'))) then 
        request:get-attribute(concat($global:login-domain, '.user')) 
    else if(xmldb:get-current-user()) then 
        xmldb:get-current-user() 
    else '';

(: Any post processing to form data happens here :)
declare function local:dispatch($nodes as node()*) as item()* {
  for $node in $nodes
  return
    typeswitch($node)
        case text() return 
            parse-xml-fragment($node)
        case element(tei:change) return
            if($node[@who = '' and @when = '']) then
                element { name($node) } 
                    { 
                        attribute who { $editor },
                        attribute when { current-date() },
                        'Record created by Syriaca.org webforms'
                    }
            else local:recurse($node)
        case element(tei:persName) return
            if($node/parent::tei:person) then 
                  element { name($node) } 
                    { 
                        attribute xml:id { concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',count($node/preceding-sibling::tei:persName) + 1) },
                        local:recurse($node)
                    }
            else 
                element { name($node) } 
                    { 
                        local:recurse($node)
                    } 
        case element(tei:placeName) return
            if($node/parent::tei:place) then 
                  element { name($node) } 
                    { 
                        attribute xml:id { concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',count($node/preceding-sibling::tei:placeName) + 1) },
                        local:recurse($node)
                    }
            else 
             element { name($node) } 
                    { 
                        local:recurse($node)
                    } 
        case element(tei:title) return
            if($node/parent::tei:bibl[parent::tei:body]) then 
                  element { name($node) } 
                    { 
                        attribute xml:id { concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',count($node/preceding-sibling::tei:title) + 1) },
                        local:recurse($node)
                    }
            else element { name($node) } 
                    { 
                        local:recurse($node)
                    }              
        case element() return local:passthru($node)
        default return local:recurse($node)
};

(: Recurse through child nodes :)
declare function local:passthru($node as node()*) as item()* {
  element {name($node)} {($node/@*, local:dispatch($node/node()))}
};

declare function local:recurse($node as item()) as item()* {
    for $node in $node/node()
    return
        local:dispatch($node)
};

let $data := request:get-parameter('postdata','')
let $results := fn:parse-xml($data)
let $id := replace($results/descendant::tei:idno[1],'/tei','')      
let $file-name := if($id != '') then concat(tokenize($id,'/')[last()], '.xml') else 'form.xml'
let $post-processed-xml := local:dispatch($results)
(:<TEI xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en">{$post-processed-xml/child::*}</TEI> :)
return 
      if(request:get-parameter('type', '') = 'view') then
        (response:set-header("Content-type", 'text/xml'),
        serialize($post-processed-xml, 
        <output:serialization-parameters>
            <output:method>xml</output:method>
            <output:media-type>text/xml</output:media-type>
        </output:serialization-parameters>))
    else if(request:get-parameter('type', '') = 'download') then
       (response:set-header("Content-Disposition", fn:concat("attachment; filename=", $file-name)),$post-processed-xml)
    else if(request:get-parameter('type', '') = 'save') then
        <response code="400">
            <message>Please download the record and save to Syriaca.org's github repository.</message>
        </response> 
        (:
        let $data-root := $global:data-root
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
                        <message>New record saved: {xmldb:store($collection, $file-name, $post-processed-xml)}</message>
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
    :)                
    else 
        <response code="500">
            <message>General Error</message>
        </response> 