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

let $results := request:get-data()
let $id := if($results/descendant::tei:idno[1] != '') then replace($results/descendant::tei:idno[1],'/tei','') else 'http://logarandes.org/place/10'      
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
    else if(request:get-parameter('type', '') = 'get-rec') then
       root(collection($global:data-root)//tei:idno[. = $id])
    else if(request:get-parameter('type', '') = 'save') then
        <response code="400">
            <message>Please download the record and save to Syriaca.org's github repository.</message>
        </response>          
    else if(request:get-parameter('type', '') = 'download') then
       (response:set-header("Content-Disposition", fn:concat("attachment; filename=", $file-name)),$post-processed-xml)
    else if(request:get-parameter('type', '') = 'save') then
        <response code="400">
            <message>Please download the record and save to Syriaca.org's github repository.</message>
        </response>         
    else if(request:get-parameter('type', '') = 'merge') then
        if($id != '') then
            let $record := root(collection($global:data-root)//tei:idno[. = $id])
            return 
                if($record) then 
                    let $change := 
                        <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#onlineForms" when="{current-date()}">
                            {string-join($results/descendant::tei:change/descendant::*,', ')}    
                        </change>
                    return
                        try{(
                            update insert $change preceding $record/descendant::tei:revisionDesc/tei:change,
                            let $container := if(name($results/descendant::tei:text/child::*)) then name($results/descendant::tei:text/child::*) else 'place'
                            let $path := concat('$post-processed-xml/descendant::tei:',$container, '/child::*')
                            let $path := '$results/descendant::tei:place'
                            for $update in util:eval($path)/child::*[not(self::tei:idno)]
                            let $element := local-name($update)
                            return 
                                update insert $update following util:eval(concat('$record/descendant::tei:',$container,'/tei:',$element)),                               
                                 <response xmlns="http://www.w3.org/1999/xhtml" status="success">
                                     <message>Record updated 7</message>
                                 </response>    
                            )}
                        catch * {
                            <response xmlns="http://www.w3.org/1999/xhtml" status="success">
                                <message>Error updating record {concat($err:code, ": ", $err:description)}</message>
                            </response>
                        }
                else 
                    <response xmlns="http://www.w3.org/1999/xhtml" status="success"><message>Merge record, can't find record: {$id}</message></response>
        else <response xmlns="http://www.w3.org/1999/xhtml" status="success"><message>New record: {$global:data-root} {$id}</message></response>
    else 
        <response code="500">
            <message>General Error</message>
        </response> 