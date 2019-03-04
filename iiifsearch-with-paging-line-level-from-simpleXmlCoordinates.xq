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

let $q := request:get-parameter('q', 'potest')
let $codex := request:get-parameter('codex', '')
let $searchuri := request:get-uri()
let $searchuribase := "http://localhost:8080"
(: full-msslug should be able to be parsed from requesting url :)
let $manifestationid := $codex


(: let $docs := if (collection(concat('/db/apps/scta-data/simpleXmlCoordinates', $commentaryid))[contains(util:document-name(.), $msslug)])
                then
                collection(concat('/db/apps/scta-data/', $commentaryid))[contains(util:document-name(.), $msslug)]
                else
                collection(concat('/db/apps/scta-data/', $commentaryid)) :)

(: let $docs := collection(concat('/db/apps/scta-data/simpleXmlCoordinates/', $msslug)) :)
let $docs := collection(concat('/db/apps/simpleXmlCoordinates/', $codex))
let $start:= xs:integer(request:get-parameter("start", "1"))
let $records := xs:integer(request:get-parameter("records", "10"))
let $page := request:get-parameter("page","1")
let $allHits := $docs//new:text[ft:query(., $q)]

let $firstPage := 1

let $startIndex :=
    if ($page != "all") then
        (xs:integer($page) - 1) * $records
    else
        0

let $lastPage :=
    if (count($allHits) mod $records = 0) then
        xs:integer(count($allHits) div $records)
    else
        (xs:integer(count($allHits) div $records)) + 1

let $nextPage :=
    if ($page != "all") then
        if (xs:integer($page) < $lastPage) then
            xs:integer($page) + 1
        else
            xs:integer($firstPage)
    else
        1

let $prevPage :=
    if ($page != "all") then
        if (xs:integer($page) > 1) then
            xs:integer($page) - 1
        else
            xs:integer($lastPage)
    else
        1


let $resultsUrl :=
        if ($page != "all") then
            concat($searchuri, "?q=", $q, "&amp;page=", $page)
        else
            concat($searchuri, "?q=", $q)


(: compute the limits for this page :)
let $start :=
        if ($page != "all") then
            (xs:integer($page)*$records) - ($records - 1)
        else
            $start


(: restrict the full set of matches to this subsequence :)
let $hits :=
        if ($page != "all") then
            subsequence($allHits,$start,$records)
        else
            $allHits


return

        map{
          "@context":"http://iiif.io/api/search/0/context.json",
          "@id": concat($searchuribase, $resultsUrl),
          "@type":"sc:AnnotationList",
          (: it would be best if the followin properties were only
          present when the page parameter is set to an integer but ignored if the search results
          are for all, but I currently can't figure out how to execute a condition here :)
          "within": map
          {
            "@id": concat($searchuribase, $searchuri, "?q=", $q),
            "@type": "sc:Layer",
            "total": count($allHits),
            "first": concat($searchuribase, $searchuri, "?q=", $q, "&amp;page=", $firstPage),
            "last": concat($searchuribase, $searchuri, "?q=", $q, "&amp;page=", $lastPage)
          },
          "next": concat($searchuribase, $searchuri, "?q=", $q, "&amp;page=", $nextPage),
          "prev": concat($searchuribase, $searchuri, "?q=", $q, "&amp;page=", $prevPage),
          "startIndex": $startIndex,




          "resources":

            for $hit in $hits

            let $coords := $hit/preceding-sibling::new:iiifAdjusted/string()
            let $lineNumber := $hit/preceding-sibling::new:lineNumber/string()
            let $surfaceId := $hit/preceding-sibling::new:surfaceId/string()
            let $surfaceIdSlug := $hit/preceding-sibling::new:surfaceIdSlug/string()
            let $canvasid := $hit/preceding-sibling::new:canvasId/string()
            let $imageUrl := $hit/preceding-sibling::new:imageUrl/string()
            let $column := $hit/preceding-sibling::new:column/string()

            let $on := concat($canvasid, '#xywh=', $coords)
            let $pageOrderNumber := $hit/preceding-sibling::new:pageOrderNumber/number()

            order by $pageOrderNumber
            return

                    map {
                        "@id": concat("http://scta.info/iiif/", $manifestationid, "/search/annotations/", $lineNumber),
                        "@type": "oa:Annotation",
                        "label": concat($surfaceIdSlug, "(", $pageOrderNumber, "),", $column, " - line: ", $lineNumber),
                        "motivation": "sc:painting",
                        "resource":
                            map {
                                "@type": "cnt:ContentAsText",
                                "chars": local:render(util:expand($hit))
                            },
                        "on": $on,
                        "imageUrl": $imageUrl,
                        "surfaceId": $surfaceId
                    }



        }
