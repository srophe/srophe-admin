xquery version "3.0";
(: Global app variables and functions. :)
module namespace global="http://syriaca.org/global";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";

declare variable $global:login-domain := "org.exist.srophe" (:"org.exist.login":);

(: Find app root, borrowed from config.xqm :)
declare variable $global:app-root :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
    ;
(: Get config.xml to parse global varaibles :)
declare variable $global:get-config := doc($global:app-root || '/repo.xml');

(: Establish data app root :)
declare variable $global:data-root :=
    let $app-root := $global:get-config//repo:app-root/text()
    let $data-root := concat($global:get-config//repo:data-root/text(),'/data')
    return
       replace($global:app-root, $app-root, $data-root)
    ;

declare variable $global:comments-root :=
    let $app-root := $global:get-config//repo:app-root/text()
    let $data-root := concat($global:get-config//repo:comments-root/text(),'/data/comments')
    return
       replace($global:app-root, $app-root, $data-root)
    ;

(: Establish main navigation for app, used in templates for absolute links :)
declare variable $global:nav-base :=
    if($global:get-config//repo:nav-base/text() != '') then $global:get-config//repo:nav-base/text()
    else concat('/exist/apps/',$global:app-root);

(: Base URI used in tei:idno :)
declare variable $global:base-uri := $global:get-config//repo:base-uri/text();
declare variable $global:public-view-base := $global:get-config//repo:public-view/text();

declare variable $global:app-title := $global:get-config//repo:title/text();

declare variable $global:app-url := $global:get-config//repo:url/text();

(: Name of logo, not currently used dynamically :)
declare variable $global:app-logo := $global:get-config//repo:logo/text();

(: Sub in relative paths based on base-url variable :)
declare function global:internal-links($uri){
    replace($uri,$global:base-uri,$global:public-view-base)
};

(:
 : Addapted from https://github.com/eXistSolutions/hsg-shell
 : Recurse through menu output absolute urls based on config.xml values.
:)
declare function global:fix-links($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(html:a) return
                let $href := replace($node/@href, "\$app-root", $global:nav-base)
                return
                    <a href="{$href}">
                        {$node/@* except $node/@href, $node/node()}
                    </a>
            case element(html:form) return
                let $action := replace($node/@action, "\$app-root", $global:nav-base)
                return
                    <form action="{$action}">
                        {$node/@* except $node/@action, global:fix-links($node/node())}
                    </form>
            case element() return
                element { node-name($node) } {
                    $node/@*, global:fix-links($node/node())
                }
            default return
                $node
};

(:~
 : Transform tei to html via xslt
 : @param $node data passed to transform
:)
declare function global:tei2html($nodes as node()*) {
    transform:transform($nodes, doc('/db/apps/srophe/resources/xsl/tei2html.xsl'),
    <parameters>
        <param name="data-root" value="{$global:data-root}"/>
        <param name="app-root" value="{$global:app-root}"/>
        <param name="nav-base" value="{$global:nav-base}"/>
        <param name="base-uri" value="{$global:base-uri}"/>
    </parameters>
    )
};

declare function global:rec-short-view($node){
let $ana := if($node/descendant-or-self::tei:person/@ana) then replace($node/descendant-or-self::tei:person/@ana,'#syriaca-','') else ()
let $type := if($node/descendant-or-self::tei:place/@type) then string($node/descendant-or-self::tei:place/@type) else ()
let $uri :=
        if($node//tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')]) then
                string(replace($node//tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')][1],'/tei',''))
        else string($node//tei:div[1]/@uri)
let $en-title :=
             if($node/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]) then
                string-join($node/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]//text(),' ')
             else $node/ancestor::tei:TEI/descendant::tei:title[1]/text()
let $syr-title :=
             if($node/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][1]) then
                string-join($node/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]/text(),' ')
             else 'NA'
let $birth := if($ana) then $node/descendant::tei:birth else()
let $death := if($ana) then $node/descendant::tei:death else()
let $dates := concat(if($birth) then $birth/text() else(), if($birth and $death) then ' - ' else if($death) then 'd.' else(), if($death) then $death/text() else())
let $desc :=
        if($node/descendant::*[starts-with(@xml:id,'abstract')]/descendant-or-self::text()) then
            $node/descendant::*[starts-with(@xml:id,'abstract')][1]/descendant-or-self::text()
        else ()
return
    <span>
       <a href="{$uri}">
        {
        ($en-title,
          if($type) then concat('(',$type,')') else (),
            if($syr-title) then
                if($syr-title = 'NA') then ()
                else (' - ', <span dir="rtl" lang="syr" xml:lang="syr">{$syr-title}</span>)
          else ' - [Syriac Not Available]')
          }
       </a>
       {if($ana != '') then
            <span class="results-list-desc" dir="ltr" lang="en">{concat('(',$ana, if($dates) then ', ' else(), $dates ,')')}</span>
        else ()}
     <span class="results-list-desc" dir="ltr" lang="en">{$desc}</span>
     {
        if($ana) then
            if($node/descendant-or-self::tei:person/tei:persName[not(@syriaca-tags='#syriaca-headword')]) then
                <span class="results-list-desc" dir="ltr" lang="en">Names:
                {
                    for $names in $node/descendant-or-self::tei:person/tei:persName[not(@syriaca-tags='#syriaca-headword')]
                    [not(starts-with(@xml:lang,'syr'))][not(starts-with(@xml:lang,'ar'))][not(@xml:lang ='en-xsrp1')]
                    return <span class="badge">{string-join($names//text(),' ')}</span>
                }
                </span>
            else()
        else()
        }
     <span class="results-list-desc"><span class="srp-label">URI: </span><a href="{$uri}">{$uri}</a></span>
    </span>
};

declare function global:get-rec($id as xs:string){
    for $rec in collection($global:data-root)//tei:idno[@type='URI'][. = $id]/ancestor::tei:TEI
    return $rec
};
