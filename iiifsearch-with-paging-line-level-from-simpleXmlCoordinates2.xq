xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace new="http://new";

declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";

import module namespace response = "http://exist-db.org/xquery/response";


declare option output:method "json";
declare option output:media-type "application/json";

declare function local:render($node) {
    typeswitch($node)
        case text() return concat(normalize-space($node), ' ')
        (: case element(new:word) return local:recurse($node) :)
        (: case element(tei:title) return <em>{local:recurse($node)}</em>
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

declare function local:getCodex($codex as xs:string) as xs:string {
    (: currently cannot get $expression_type_id passed into query string; so it is currently hard coded to librum1-prologus :)
let $query := xs:string('
      SELECT ?codex ?codexTitle
      WHERE
      {
          <http://scta.info/resource/' || $codex || '> a <http://scta.info/resource/codex> .
          <http://scta.info/resource/' || $codex || '> <http://purl.org/dc/elements/1.1/title> ?codexTitle .

      }
    ')
    return $query
};

declare function local:getAllCodices() as xs:string {
    (: currently cannot get $expression_type_id passed into query string; so it is currently hard coded to librum1-prologus :)
let $query := xs:string('
    SELECT ?codex ?codexTitle ?date
    WHERE
    {
        ?codex a <http://scta.info/resource/codex> .
        ?codex <http://purl.org/dc/elements/1.1/title> ?codexTitle .
        OPTIONAL{
          ?codex <http://scta.info/property/publicationDate> ?date.
        }
    }
    ORDER BY ?date
    ')
    return $query
};
declare function local:getCodicesByAfterDate($date as xs:string) as xs:string {
    (: currently cannot get $expression_type_id passed into query string; so it is currently hard coded to librum1-prologus :)
let $query := xs:string('
    SELECT ?codex ?codexTitle ?date
    WHERE
    {
        ?codex a <http://scta.info/resource/codex> .
        ?codex <http://purl.org/dc/elements/1.1/title> ?codexTitle .
        ?codex <http://scta.info/property/publicationDate> ?date .
        FILTER(?date >= "' || $date || '") .
    }
    ORDER BY ?date
    ')
    return $query
};
declare function local:getAllCodicesByInstitution($institution as xs:string) as xs:string {
let $query := xs:string('
    SELECT ?codex ?codexTitle
    WHERE
    {
        ?codex a <http://scta.info/resource/codex> .
        ?codex <http://purl.org/dc/elements/1.1/title> ?codexTitle .
        ?codex <http://scta.info/property/hasCanonicalCodexItem> ?icodex .
        ?icodex <http://scta.info/property/holdingInstitution> <http://scta.info/resource/' || $institution || '> .
    }
    ')
    return $query
};

(: set response header :)

let $response-header := response:set-header("Access-Control-Allow-Origin", "*")

let $q := request:get-parameter('q', 'potest')
let $codex := request:get-parameter('codex', '')
let $institution := request:get-parameter('institution', '')
let $afterDate := request:get-parameter('afterDate', '')
let $searchuri := request:get-uri()
(: would like to use conditional here to set $searchuribase but it doesn't seem to be working
 if (fn:environment-variable("EXIST_DEVELOPMENT") eq "true") then) :)
let $searchuribase := "http://localhost:8080"
(: let $searchuribase := "https://exist.scta.info" :)
(: full-msslug should be able to be parsed from requesting url :)
let $manifestationid := $codex

(: let $url := "https://sparql-docker.scta.info/ds/query?query=" :)
let $url := "http://localhost:3030/ds/query?query="
let $sparql := if ($codex != '') then
    local:getCodex($codex)
  else if ($institution) then
    local:getAllCodicesByInstitution($institution)
  else if ($afterDate) then
    local:getCodicesByAfterDate($afterDate)
  else
    local:getAllCodices()


let $encoded-sparql := encode-for-uri($sparql)

let $sparql-result := http:send-request(
   <http:request href="{concat($url, $encoded-sparql)}" method="get">
      <http:header name="accept" value="application/xml"/>
   </http:request>
)


(: let $testList := <list><item>lon</item><item>penn</item><item>penn855</item></list> :)
for $result in $sparql-result//sparql:result

  let $url-array := fn:tokenize($result/sparql:binding[@name="codex"]/sparql:uri/text(), "/")
  let $item := if ($codex != '') then
      $codex
    else
      $url-array[last()]

  let $codexDate := $result/sparql:binding[@name="date"]/sparql:literal/text()
  let $codexTitle := $result/sparql:binding[@name="codexTitle"]/sparql:literal/text()

let $docs := collection(concat('/db/apps/simpleXmlCoordinates/', $item))
let $start:= xs:integer(request:get-parameter("start", "1"))
let $records := xs:integer(request:get-parameter("records", "5"))
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
            concat($searchuri, "?q=", $q, "&amp;page=", $page, "&amp;codex=", $item)
        else
            concat($searchuri, "?q=", $q, "&amp;codex=", $item)


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

where count($allHits) > 0
return

        map{
          "@context":"http://iiif.io/api/search/0/context.json",
          "@id": concat($searchuribase, $resultsUrl),
          "@type":"sc:AnnotationList",
          "label": concat($codexTitle, ' (', $codexDate, ')'),
          (: it would be best if the followin properties were only
          present when the page parameter is set to an integer but ignored if the search results
          are for all, but I currently can't figure out how to execute a condition here :)
          "within": map
          {
            "@id": concat($searchuribase, $searchuri, "?q=", $q),
            "@type": "sc:Layer",
            "total": count($allHits),
            "first": concat($searchuribase, $searchuri, "?q=", $q, "&amp;page=", $firstPage, "&amp;codex=", $item),
            "last": concat($searchuribase, $searchuri, "?q=", $q, "&amp;page=", $lastPage, "&amp;codex=", $item)
          },
          "next": concat($searchuribase, $searchuri, "?q=", $q, "&amp;page=", $nextPage, "&amp;codex=", $item),
          "prev": concat($searchuribase, $searchuri, "?q=", $q, "&amp;page=", $prevPage, "&amp;codex=", $item),
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
                        "@id": concat("http://scta.info/iiif/search/annotations/", $item, "/", $surfaceIdSlug, "/", $lineNumber),
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
