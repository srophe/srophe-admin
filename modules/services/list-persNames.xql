xquery version "3.0";
(:~
 : Build dropdown list of available resources for citation
:)

import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

<names>
{
let $names :=
    <names>{
    for $r in collection('/db/apps/srophe-data/data/persons/tei')//tei:persName[starts-with(@xml:lang,'en')]
    let $name := string-join($r/descendant-or-self::*/text(),' ')
    order by string-length($name) descending
    return <persName>{replace($name,'\(|\)','')}</persName>
    }</names>

(: Run with elevated privs. :)
(:xmldb:store($collection-uri as xs:string, $resource-name as xs:string?,
$contents as item()) as xs:string?:)
return
(xmldb:store('/db/apps/srophe-forms/data','persNames.xml', $names),$names)
}</names>