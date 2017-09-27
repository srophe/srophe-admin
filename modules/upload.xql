xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
declare option exist:serialize "method=html media-type=text/html indent=no";

let $name := request:get-uploaded-file-name("fileUpload")
let $file := request:get-uploaded-file-data("fileUpload")
let $module-name := request:get-parameter('module', '')
let $config := 
    if(exists(doc($global:public-view-base || '/repo.xml'))) then 
        if(doc($global:public-view-base || '/repo.xml')//repo:collection[@title = $module-name]) then
            doc($global:public-view-base || '/repo.xml')//repo:collection[@title = $module-name]
        else <error>No matching name in repo.xml </error>
    else <error>No repo.xml file </error>
let $uri-mod-name := 
    if($config) then 
        string($config/@data-root)
    else <error>No matching name in repo.xml </error>
let $uri :=
    if($config) then 
        concat($config/@record-URI-pattern, substring-before($name,'.xml'))
    else if($global:base-uri = 'http://syriaca.org') then 
        concat($global:base-uri,'/', $uri-mod-name ,'/', substring-before($name,'.xml'))
    else concat($global:base-uri, '/', substring-before($name,'.xml'))                
let $user:= request:get-attribute("org.exist.demo.login.user")
let $user-name := if ($user) then sm:get-account-metadata($user, xs:anyURI('http://axschema.org/namePerson')) else xmldb:get-current-user()
let $collection-path as xs:anyURI := xs:anyURI($global:data-root || '/' || $uri-mod-name || '/tei')
return
    <div id="response">{
        try {(
            <p style="display:none;">{(xmldb:store($collection-path, xmldb:encode-uri($name), $file))}</p>,
            <h4>Upload complete!</h4>,
            <p>Sub mod name: {$uri-mod-name}</p>,
            <p class="indent">File <strong>{$name}</strong> has been saved to:<strong>{substring-after($collection-path,$global:data-root)}</strong>.</p>,
            <p class="indent alert alert-info">Review record: <a href="{concat('../review-rec.html?id=',$uri)}">{$uri}</a></p>
            )}
        catch * {(
            <p class="bg-danger">{concat($err:code, ": ", $err:description)}</p>,
            <p>{xmldb:get-current-user()}</p>
        )}
    }</div>
