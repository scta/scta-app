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

declare function local:getSparqlQuery($surface_id) as xs:string {
  let $query := xs:string('
  SELECT ?surface_title ?next_surface_title ?manifestation_item ?short_id ?topLevelExpression_short_id ?canvas
    WHERE
    {
        <' || $surface_id || '> <http://scta.info/property/hasISurface> ?isurface .
        <' || $surface_id || '> <http://purl.org/dc/elements/1.1/title> ?surface_title .
        OPTIONAL
        {
          <' || $surface_id || '> <http://scta.info/property/next> ?next_surface .
          ?next_surface <http://purl.org/dc/elements/1.1/title> ?next_surface_title .
        }
        ?isurface <http://scta.info/property/hasCanvas> ?canvas .
        ?manifestation_item <http://scta.info/property/isOnSurface> <' || $surface_id || '> .
        ?manifestation_item <http://scta.info/property/structureType> <http://scta.info/resource/structureItem> .
        ?manifestation_item <http://scta.info/property/shortId> ?short_id .
        ?manifestation_item <http://scta.info/property/isManifestationOf> ?expression_item .
        ?expression_item <http://scta.info/property/isPartOfTopLevelExpression> ?topLevelExpression .
        ?topLevelExpression <http://scta.info/property/shortId> ?topLevelExpression_short_id .
    }
      ')
      return $query
};

(: set response header :)
let $response-header := response:set-header("Access-Control-Allow-Origin", "*")

(: main query :)
let $surface_id := request:get-parameter('surface_id', 'http://scta.info/resource/sorb/20r')
let $url := "http://sparql-docker.scta.info/ds/query?query=",
$sparql := local:getSparqlQuery($surface_id),
$encoded-sparql := encode-for-uri($sparql),

$sparql-result := http:send-request(
   <http:request href="{concat($url, $encoded-sparql)}" method="get">
      <http:header name="accept" value="application/xml"/>
   </http:request>
)

return

    map{
        "@context": "http://iiif.io/api/presentation/2/context.jsonld",
        "@id": "http://exist.scta.info/exist/apps/scta-app/folio-annotation-list.xq?surface_id=" || $surface_id,
        "@type": "sc:AnnotationList",
        "within": map {
          "@id": "http://scta.info/iiif/sorb/layer/transcription",
          "@type": "sc:Layer",
          "label": "Diplomatic Transcription"
        },
        "resources":



for $result at $count in $sparql-result//sparql:result
  (:its not ideal to be parsing the string this way; sparql should retrieve a property called existdb path :)
  let $prefix := tokenize($result//sparql:binding[@name="short_id"]/sparql:literal/text(), "/")[2]
  let $fs := tokenize($result//sparql:binding[@name="short_id"]/sparql:literal/text(), "/")[1]
  let $dir := $result//sparql:binding[@name="topLevelExpression_short_id"]/sparql:literal/text()
  let $docpath := concat('/db/apps/scta-data/', $dir, '/', $fs, '/', $prefix, "_", $fs, '.xml')
  let $doc := doc($docpath)
  let $canvasid := $result//sparql:binding[@name="canvas"]/sparql:uri/text()

  (: this is extremely fragile; if the label isn't right this won't work
  if the econding in lbp-schema 1.0 this won't work :)
  (: need a switch here to handle lbp-1.0 guidlines and 0.0 guidelines as well
  as cases where there are no column breaks and only page breaks :)
  let $surface_title := $result//sparql:binding[@name="surface_title"]/sparql:literal/text()
  let $next_surface_title := $result//sparql:binding[@name="next_surface_title"]/sparql:literal/text()
  let $schema := if ($doc/tei:TEI/tei:teiHeader[1]/tei:encodingDesc[1]/tei:schemaRef[1]/@n) then (
    string($doc/tei:TEI/tei:teiHeader[1]/tei:encodingDesc[1]/tei:schemaRef[1]/@n)
    )
    else(
      "lbp-diplomatic-0.0.0"
    )
  let $surface_number_start := if ($schema eq "lbp-diplomatic-0.0.0") then (
    concat($surface_title, "a")
  )
  else (
    if (contains($surface_title, "r")) then (
      concat(substring-before($surface_title, "r"), "-r")
    )
    else if (contains($surface_title, "v")) then (
      concat(substring-before($surface_title, "v"), "-v")
    )
    else()
  )
  let $surface_number_end := if ($schema eq "lbp-diplomatic-0.0.0") then (
    concat($next_surface_title, "a")
    )
    else (
      if (contains($next_surface_title, "r")) then (
        concat(substring-before($next_surface_title, "r"), "-r")
      )
      else if (contains($next_surface_title, "v")) then (
        concat(substring-before($next_surface_title, "v"), "-v")
      )
      else()
    )


  let $initial := if ($doc//tei:witness/@n=$prefix) then
      $doc//tei:witness[@n=$prefix]/@xml:id
     else
      upper-case(substring($prefix,1,1))
  let $initial_with_hash := concat("#", $initial)

  let $beginning-node := if ($schema eq "lbp-diplomatic-0.0.0") then (
      if ($doc/tei:TEI//tei:body//tei:cb[@ed=$initial_with_hash][@n=$surface_number_start]) then
        $doc/tei:TEI//tei:body//tei:cb[@ed=$initial_with_hash][@n=$surface_number_start]
      else
        $doc/tei:TEI//tei:body/tei:div
      )
      else(
        if ($doc/tei:TEI//tei:body//tei:pb[@ed=$initial_with_hash][@n=$surface_number_start]) then
          $doc/tei:TEI//tei:body//tei:pb[@ed=$initial_with_hash][@n=$surface_number_start]
        else
          $doc/tei:TEI//tei:body/tei:div
      )
  let $ending-node := if ($schema eq "lbp-diplomatic-0.0.0") then (
    if ($doc/tei:TEI//tei:body//tei:cb[@ed=$initial_with_hash][@n=$surface_number_end]) then
      $doc/tei:TEI//tei:body//tei:cb[@ed=$initial_with_hash][@n=$surface_number_end]
    else
      $doc/tei:TEI//tei:body//tei:cb[@ed=$initial_with_hash][@n=$surface_number_start]//following
    )
    else(
      if ($doc/tei:TEI//tei:body//tei:pb[@ed=$initial_with_hash][@n=$surface_number_end]) then
        $doc/tei:TEI//tei:body//tei:pb[@ed=$initial_with_hash][@n=$surface_number_end]
      else
        $doc/tei:TEI//tei:body//tei:pb[@ed=$initial_with_hash][@n=$surface_number_start]//following
    )
  let $make-fragment := true()
  let $display-root-namespace := true()
  let $fragment := util:get-fragment-between($beginning-node, $ending-node, $make-fragment, $display-root-namespace)
  let $node := util:parse($fragment)
  let $current_offset := ($count * 200) + 10

  return


              map {
                  "@type": "oa:Annotation",
                  "@id": "http://scta.info/iiif/"|| $prefix ||"/"|| $surface_title ||"/annotation/transcription/" || $count,
                  "motivation": "sc:painting",
                  "resource": map {
                      "@id": "http://scta.lombardpress.org/text/plaintext/"|| $prefix ||"/"|| $surface_title ||"/transcription/" || $count,
                      "@type": "dctypes:Text",
                      "chars": string-join(local:render($node)),
                      "format": "text/html",
                      "label": $fs,
                      "end": $next_surface_title
                  },
          "on": $canvasid || "#xywh=0,"|| $current_offset ||",300,200"

              }


      }
