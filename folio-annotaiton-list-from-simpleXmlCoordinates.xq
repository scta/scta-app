xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace new="http://new";

import module namespace response = "http://exist-db.org/xquery/response";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";


declare option output:method "json";
declare option output:media-type "application/json";

declare function local:render($node) {
    typeswitch($node)
        case text() return concat($node, ' ')
        (: case element(tei:p) return <p>{local:recurse($node)}</p>
        case element(tei:title) return <em>{local:recurse($node)}</em>
        case element(tei:name) return <span style="font-variant: small-caps">{local:recurse($node)}</span> :)
        case element(exist:match) return <span style="background-color: yellow;">{local:recurse($node)}</span>
        (: case element(tei:rdg) return ()
        case element(tei:bibl) return ()
        case element (tei:note) return () :)
        default return local:recurse($node)
};

declare function local:recurse($node) {
    for $child in $node/node()
    return
        local:render($child)
};


(: set response header :)

let $response-header := response:set-header("Access-Control-Allow-Origin", "*")
let $surfaceid := request:get-parameter('surfaceid', 'lon/12v')
let $coordTightness := request:get-parameter('coords', 'tight')
let $doc := doc(concat('/db/apps/simpleXmlCoordinates/', $surfaceid, '.xml'))

return

        map{
          "@context":"http://iiif.io/api/search/0/context.json",
          "@id": concat("http://exist.scta.info/", $surfaceid),
          "@type":"sc:AnnotationList",
          "resources":

            for $line at $count in $doc//new:line

            let $coords := if ($coordTightness eq "tight") then $line/new:iiif/string() else $line/new:iiifAdjusted/string()
            let $lineNumber := $line/new:lineNumber/string()
            let $column := $line/new:column/string()
            let $surfaceId := $line/new:surfaceIdSlug/string()
            let $canvasid := $line/new:canvasId/string()
            let $imageUrl := $line/new:imageUrl/string()
            let $text := $line/new:text
            let $on := concat($canvasid, '#xywh=', $coords)
            let $pageOrderNumber := $line/new:pageOrderNumber/number()
            return

                    map {
                        "@id": concat("http://scta.info/iiif/", $surfaceid, '/', $lineNumber),
                        "@type": "oa:Annotation",
                        "label": concat($surfaceId, "(", $pageOrderNumber, "),", $column, " - line: ", $lineNumber),
                        "motivation": "sc:painting",
                        "resource":
                            map {
                                "@type": "cnt:ContentAsText",
                                "chars": local:render(util:expand($text))
                            },
                        "on": $on,
                        "imageUrl": $imageUrl
                    }



        }
