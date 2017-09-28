xquery version "3.1";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace global="http://syriaca.org/global" at "modules/lib/global.xqm";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
(: Used to test vars 
<div>
    <p>$exist:path: {$exist:path}</p>
    <p>$exist:resource: {$exist:resource}</p>
    <p>$exist:controller: {$exist:controller}</p>
    <p>$exist:prefix: {$exist:prefix}</p>
    <p>$global:public-view-base: {$global:public-view-base}</p>
</div>
:)

declare variable $logout := request:get-parameter("logout", ());
declare variable $login := request:get-parameter("user", ());

if ($exist:path eq "") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat(request:get-uri(), '/')}"/>
    </dispatch>
else if ($exist:path eq "/") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
else if ($exist:path eq "/oauth") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/services/sosol.xql">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>
else if (ends-with($exist:resource, ".xql")) then (
    login:set-user($global:login-domain, (), false()),
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="no"/>
    </ignore>

) else if ($logout or $login) then (
    login:set-user($global:login-domain, (), false()),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{replace(request:get-uri(), "^(.*)\?", "$1")}"/>
    </dispatch>

) else if (ends-with($exist:resource, ".html")) then (
    login:set-user($global:login-domain, (), false()),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/modules/view.xql">
                {login:set-user("org.exist.demo.login", (), true())}
                <set-attribute name="$exist:prefix" value="{$exist:prefix}"/>
                <set-attribute name="$exist:controller" value="{$exist:controller}"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{$exist:controller}/error-page.html" method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
    </dispatch>
)
else if (contains($exist:path, "/$main-module/")) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat(replace($global:public-view-base,'/exist/apps',''),'/',substring-after($exist:path, '/$main-module/'))}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>
(: Resource paths starting with $app-root are resolved relative to app :)
else if (contains($exist:path, "/$app-root/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat($exist:controller,'/', substring-after($exist:path, '/$app-root/'))}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>
else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>

(: images, css are contained in the top /resources/ collection. :)
(: Relative path requests from sub-collections are redirected there :)
else if (contains($exist:path, "/resources/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/resources/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>
else if (contains($exist:path, "/forms/")) then
(
    login:set-user($global:login-domain, (), false()),
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="no"/>
    </ignore>)
else
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </ignore>