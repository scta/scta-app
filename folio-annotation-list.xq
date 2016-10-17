xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";


declare option output:method "json";
declare option output:media-type "application/json";

import module namespace response = "http://exist-db.org/xquery/response";
import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";


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
        ?manifestation_item <http://scta.info/property/hasSurface> <' || $surface_id || '> .
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
let $surface_id := request:get-parameter('surface_id', 'http://scta.info/resource/wettf15/108r')
let $url := "http://localhost:3030/ds/query?query=",
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
        "@id": "http://scta.info/iiif/test/list/",
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
  let $surface_title := $result//sparql:binding[@name="surface_title"]/sparql:literal/text()
  let $next_surface_title := $result//sparql:binding[@name="next_surface_title"]/sparql:literal/text()
  let $surface_number_start := concat($surface_title, "a")
  let $surface_number_end := concat($next_surface_title, "a")

  let $initial := if ($doc//tei:witness/@n=$prefix) then
      $doc//tei:witness[@n=$prefix]/@xml:id
     else
      upper-case(substring($prefix,1,1))
  let $initial_with_hash := concat("#", $initial)

  let $beginning-node := if ($doc/tei:TEI//tei:body//tei:cb[@ed=$initial_with_hash][@n=$surface_number_start]) then
      $doc/tei:TEI//tei:cb[@ed=$initial_with_hash][@n=$surface_number_start]
    else
      $doc/tei:TEI//tei:body/tei:div
  let $ending-node := if ($doc/tei:TEI//tei:body//tei:cb[@ed=$initial_with_hash][@n=$surface_number_end]) then
      $doc/tei:TEI//tei:cb[@ed=$initial_with_hash][@n=$surface_number_end]
    else
      $doc/tei:TEI//tei:cb[@ed=$initial_with_hash][@n=$surface_number_start]//following

  let $make-fragment := true()
  let $display-root-namespace := true()
  let $fragment := util:get-fragment-between($beginning-node, $ending-node, $make-fragment, $display-root-namespace)
  let $node := util:parse($fragment)
  let $current_offset := ($count * 200) + 100

  return


              map {
                  "@type": "oa:Annotation",
                  "@id": "http://scta.info/iiif/"|| $prefix ||"/"|| $surface_title ||"/annotation/transcription/" || $count,
                  "motivation": "sc:painting",
                  "resource": map {
                      "@id": "http://scta.lombardpress.org/text/plaintext/"|| $prefix ||"/"|| $surface_title ||"/transcription/" || $count,
                      "@type": "dctypes:Text",
                      "chars": $node/string(),
                      "format": "text/html",
                      "label": $fs
                  },
          "on": $canvasid || "#xywh=1000,"|| $current_offset ||",300,100"

              }


      }
