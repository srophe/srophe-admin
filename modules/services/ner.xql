xquery version "3.0";

import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace fn="http://www.w3.org/2005/xpath-functions";

(:declare variable $id {request:get-parameter('id', '')};:)
declare variable $id {request:get-parameter('id', '')};
declare variable $url {request:get-parameter('url', '')};

declare function local:highlight-matches($nodes as node()*, $pattern as xs:string*, $highlight as function(xs:string) as item()* ) {
    for $node in $nodes
    return
        typeswitch ( $node )
            (: Ignores existing teiHeader
            case element(tei:teiHeader) return
                $node
                :)
            case element(tei:revisionDesc) return
                (<change who="http://syriaca.org/documentation/editors.xml#admin" when="{current-date()}">ADDED: persName and placeName elements via Syriaca.org NER script.</change>,
                $node)
            case element(tei:idno) return
                $node
            (: Ignores existing placeNames :)
            case element(tei:placeName) return
                if($node/@ref != '' or $node/@xml:id) then $node
                else
                    <placeName xmlns="http://www.tei-c.org/ns/1.0">
                        {
                            if(local:get-place-id($node/string()) != "") then
                                attribute ref { local:get-place-id($node/string()) }
                            else ()
                        }
                        {$node/string()}
                     </placeName>
            (: Ignores existing placeNames :)
            case element(tei:persName) return
                if($node/@ref != '' or $node/@xml:id) then $node
                else
                    <persName xmlns="http://www.tei-c.org/ns/1.0">
                        {
                            if(local:get-pers-id($node/string()) != "") then
                                attribute ref { local:get-pers-id($node/string()) }
                            else ()
                        }
                        {$node/string()}
                    </persName>
            (: Ignores existing bibl :)
            case element(tei:bibl) return
                $node
            case element() return
                element { QName(namespace-uri($node), local-name($node)) } { $node/@*, local:highlight-matches($node/node(), $pattern, $highlight) }
            case text() return $node
            (:
                let $normalized := replace($node, '\s+', ' ')
                for $segment in analyze-string($normalized, $pattern)/node()
                return
                    if ($segment instance of element(fn:match)) then
                        $highlight($segment/string())
                    else
                        $segment/string()
                        :)
            case document-node() return
                document { local:highlight-matches($node/node(), $pattern, $highlight) }
            default return
                $node
};

declare function local:get-persNames(){
    doc('/db/apps/srophe-forms/services/persNames.xml')
};

declare function local:get-placeNames(){
    doc('/db/apps/srophe-forms/services/placeNames.xml')
};

declare function local:get-pers-id($string as xs:string) as xs:string*{
    let $id := local:get-persNames()//tei:persName[matches(.,$string)]/@ref/string()
    return $id
};

declare function local:get-place-id($string as xs:string) as xs:string*{
    let $id := local:get-placeNames()//tei:placeName[matches(.,$string)]/@ref/string()
    return $id
};

declare function local:resolve-conflict($id as xs:string, $ref as xs:string){
(: Not sure how to make this work, thinking.... :)
    let $rec := global:get-rec($id)
    let $element := ''
    return 'Testing'
};

declare function local:rec-short-view($node){
let $ana := if($node/descendant-or-self::tei:person/@ana) then replace($node/descendant-or-self::tei:person/@ana,'#syriaca-','') else ()
let $type := if($node/descendant-or-self::tei:place/@type) then string($node/descendant-or-self::tei:place/@type) else ()
let $uri :=
        if($node//tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')]) then
                string(replace($node//tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')][1],'/tei',''))
        else string($node//tei:div[1]/@uri)
let $en-title :=
             if($node/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/child::*) then
                 string-join($node/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/child::*/text(),' ')
             else if(string-join($node/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/text())) then
                string-join($node/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/text(),' ')
             else $node/ancestor::tei:TEI/descendant::tei:title[1]/text()
let $syr-title :=
             if($node/descendant::*[@syriaca-tags='#syriaca-headword'][1]) then
                if($node/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^syr')][1]/child::*) then
                 string-join($node/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^syr')][1]/child::*/text(),' ')
                else string-join($node/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^syr')][1]/text(),' ')
             else 'NA'
let $birth := if($ana) then $node/descendant::tei:birth else()
let $death := if($ana) then $node/descendant::tei:death else()
let $dates := concat(if($birth) then $birth/text() else(), if($birth and $death) then ' - ' else if($death) then 'd.' else(), if($death) then $death/text() else())
let $desc :=
        if($node/descendant::*[starts-with(@xml:id,'abstract')]/descendant-or-self::text()) then
            $node/descendant::*[starts-with(@xml:id,'abstract')]/descendant-or-self::text()
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
       {if($ana) then
            <span class="results-list-desc" dir="ltr" lang="en">{concat('(',$ana, if($dates) then ', ' else(), $dates ,')')}</span>
        else ()}
     <span class="results-list-desc" dir="ltr" lang="en">{concat($desc,' ')}</span>
     {
        if($ana) then
            if($node/descendant-or-self::tei:person/tei:persName[not(@syriaca-tags='#syriaca-headword')]) then
                <span class="results-list-desc" dir="ltr" lang="en">Names:
                {
                    for $names in $node/descendant-or-self::tei:person/tei:persName[not(@syriaca-tags='#syriaca-headword')]
                    [not(starts-with(@xml:lang,'syr'))][not(starts-with(@xml:lang,'ar'))][not(@xml:lang ='en-xsrp1')]
                    return <span class="pers-label badge">{$names}</span>
                }
                </span>
            else()
        else()
        }
     <span class="results-list-desc"><span class="srp-label">URI: </span><a href="{$uri}">{$uri}</a></span>
    </span>
};

let $doc :=
    if($url) then doc('http://localhost:8080/exist/apps/srophe-forms/data/spear-names.xml')
    else global:get-rec($id)
let $doc-name := util:document-name($doc)
let $doc-uri := base-uri($doc)
let $doc-coll := replace($doc-uri,concat('/',$doc-name),'')

let $highlight := function($string as xs:string) {
    <persName xmlns="http://www.tei-c.org/ns/1.0">
        {if(local:get-pers-id($string) != "") then
            attribute ref2 {local:get-pers-id($string) }
        else()}
        {$string}
    </persName>
    }
let $pattern := 'pattern'

let $do-highlight := local:highlight-matches($doc, $pattern, $highlight)
let $conflicts := count($do-highlight//tei:persName[contains(@ref,' ')] | $do-highlight//tei:placeName[contains(@ref,' ')])
let $no-match-person := count($do-highlight/descendant::tei:persName[not(@ref) and not(parent::tei:person)])
let $no-match-place := count($do-highlight/descendant::tei:placeName[not(@ref) and not(parent::tei:place)])
(:let $save := (xmldb:login('/db/apps/srophe/', 'admin', '', true()), xmldb:store($doc-coll,$doc-name, $do-highlight), $do-highlight):)
return
    <div>
        <h4>NER Results</h4>
        <p class="bg-info" style="padding:.25em;"><i>Current implementation looks for persName and placeName elements with no ref attributes and adds a ref attribute if a match is found. More options will be added in the future.</i></p>
        <ul>
            <li>{$conflicts} placeName(s) and/or personName(s) with conflicts that need to be resolved:
                <ul>
                    {(
                        for $pers in $do-highlight//tei:persName[contains(@ref,' ')]
                        let $related :=
                            <ul class="list-unstyled">{
                                for $ref in tokenize($pers/@ref/string(),' ')
                                (:Add link to do the resolution online, can be an xupdate, since doc has been saved:)
                                return
                                <li>
                                    {local:rec-short-view(global:get-rec($ref))}
                                </li>
                                }</ul>
                        return <li>{($pers,$related)}</li>
                        ,
                      for $place in $do-highlight//tei:placeName[contains(@ref,' ')]
                      let $related :=
                            <ul class="list-unstyled">{
                                for $ref in tokenize($place/@ref/string(),' ')
                                return
                                    <li>
                                       <!-- <a class="update" href="/exist/apps/srophe-forms/services/run-test.xql?id={$id}&qmp;ref={$ref}" style="margin-left:-1.5em; padding-right:.75em; color:green;">
                                        <i class="glyphicon glyphicon-check"></i></a>-->
                                        {local:rec-short-view(global:get-rec($ref))}
                                    </li>
                                }</ul>
                      return
                        <li>{($place,$related)}</li>
                    )}
                </ul>
            </li>
            <li>There were {$no-match-person} persons with no matching name in the Syriaca.org database
                <ul>
                    {
                        for $pers in $do-highlight//tei:persName[not(@ref) and not(parent::tei:person)] return
                         <li>{$pers}</li>
                    }
                </ul>
            </li>
            <li>There were {$no-match-place} places with no matching name in the Syriaca.org database
                <ul>
                    {
                        for $place in $do-highlight//tei:placeName[not(@ref) and not(parent::tei:place)] return
                         <li>{$place}</li>
                    }
                </ul>
            </li>
        </ul>
    </div>