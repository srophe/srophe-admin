(:~
 : Force download of xml
 :)
xquery version "3.0";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";

declare variable $id {request:get-parameter('id', '') cast as xs:string};

let $doc := global:get-rec($id)
let $uri := document-uri($doc/root())
let $filename := util:document-name($doc)
return
(
    response:set-header("Content-Disposition", fn:concat("attachment; filename=", $filename)),doc($uri)
)
