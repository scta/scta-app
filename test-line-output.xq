xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";


declare option output:method "json";
declare option output:media-type "application/json";

import module namespace response = "http://exist-db.org/xquery/response";
import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";

declare function local:render($node) {
    typeswitch($node)
        case text() return concat(normalize-space($node), " ")
        case element(tei:corr) return ()
        case element(tei:reg) return ()
        case element(tei:note) return ()
        case element(tei:lb) return "<br/> * "
        case element(tei:cb) return "<br/> [column break] "
        case element(tei:pb) return "<br/> [page break] "
        case element(tei:head) return ()
        default return local:recurse($node)
};

declare function local:recurse($node) {
    for $child in $node/node()
    return
        local:render($child)
};


let $dir := "graciliscommentary"
let $fs := "pg-b1q2"
let $prefix := "lon"
let $docpath := concat('/db/apps/scta-data/', $dir, '/', $fs, '/', $prefix, "_", $fs, '.xml')
let $make-fragment := true()
let $display-root-namespace := true()
let $doc := doc($docpath)


let $begp-node := $doc//tei:pb[@n="15-v"]
let $endp-node := $doc//tei:pb[@n="16-r"]
let $p-fragment := util:get-fragment-between($begp-node, $endp-node, $make-fragment, $display-root-namespace)
let $p-node := util:parse($p-fragment)


(:let $lines := $doc//following::tei:lb[following::tei:pb[@n="16-v"]]:)
(:let $lines := $doc//following::tei:lb[preceding::tei:pb[@n="15-v"] and not(preceding::tei:pb[@n="16-r"])]:)
(:let $lines := $doc//following::tei:lb[preceding::tei:pb[@n="16-r"][1]]:)
let $lines := $p-node//tei:lb

        for $line at $pos in $lines
            let $make-fragment1 := true()
            let $display-root-namespace1 := true()
            let $beginning-node := $line
            let $ending-node := $p-node//tei:body/tei:div/tei:p[1]/tei:lb[1]/following::tei:lb[$pos]
            return $ending-node
(:            let $fragment := util:get-fragment-between($beginning-node, $ending-node, $make-fragment1, $display-root-namespace1):)
(:            return $fragment:)
(:            let $node := util:parse($fragment):)
(::)
(:    return :)
(:        $line:)
(:        map{:)
(:            "begin-position": $pos,:)
(:            "fragment": string-join(local:render($node)):)
(:        }:)
