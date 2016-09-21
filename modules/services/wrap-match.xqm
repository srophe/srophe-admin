xquery version "3.0";
module namespace hm="http://syriaca.org/match";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace fn="http://www.w3.org/2005/xpath-functions";
import module namespace functx="http://www.functx.com";

(: Search within $nodes for matches to a regular expression $pattern and apply a $highlight function :)
declare function hm:highlight-matches($nodes as node()*, $pattern as xs:string*, $highlight as function(xs:string) as item()* ) {
    for $node in $nodes
    return
        typeswitch ( $node )
            (: Ignores existing teiHeader :)
            case element(tei:teiHeader) return
                $node
            case element(tei:idno) return
                $node
            (: Ignores existing placeNames :)
            case element(tei:placeName) return
                if($node/@xml:id) then $node
                else if($node/@ref != '') then $node
                else
                    element { QName(namespace-uri($node), local-name($node)) } { $node/@*, hm:highlight-matches($node/node(), $pattern, $highlight) }
            (: Ignores existing placeNames :)
            case element(tei:persName) return
                if($node/@xml:id) then $node
                else if($node/@ref != '') then $node
                else
                    element { QName(namespace-uri($node), local-name($node)) } { $node/@*, hm:highlight-matches($node/node(), $pattern, $highlight) }
            (: Ignores existing bibl :)
            case element(tei:bibl) return
                $node
            case element() return
                element { QName(namespace-uri($node), local-name($node)) } { $node/@*, hm:highlight-matches($node/node(), $pattern, $highlight) }
            case text() return
                let $normalized := replace($node, '\s+', ' ')
                for $segment in analyze-string($normalized, $pattern)/node()
                return
                    if ($segment instance of element(fn:match)) then
                        $highlight($segment/string())
                    else
                        $segment/string()
            case document-node() return
                document { hm:highlight-matches($node/node(), $pattern, $highlight) }
            default return
                $node
};
