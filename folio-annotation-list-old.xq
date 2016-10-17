xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare option output:method "json";
declare option output:media-type "application/json";

import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";

declare function local:getSparqlQuery($surface) as xs:string {
  let $query := xs:string('
      SELECT ?manifestation_item ?short_id
      WHERE
      {
          ?manifestation_item <http://scta.info/property/hasSurface> <http://scta.info/resource/sorb/2r> .
          ?manifestation_item <http://scta.info/property/shortId> ?short_id .
      }
     
  return $query
  }

(: main query :)
let $url := "http://sparql-staging.scta.info/ds/query?query="
let $sparql := local:getSparqlQuery($surface)
let $encoded-sparql := encode-for-uri($sparql)

let $sparql-result := http:send-request(
   <http:request href="{concat($url, $encoded-sparql)}" method="get">
      <http:header name="accept" value="application/xml"/>
   </http:request>
)

for $result in $sparql-result//sparql:result
return
    {$result}

(:

let $doc := doc('/db/apps/scta-data/plaoulcommentary/lectio2/lectio2.xml')
let $canvasid := "test"
let $beginning-node := $doc/tei:TEI//tei:cb[@ed="#V"][2]
let $ending-node := $doc/tei:TEI//tei:cb[@ed="#V"][3]
let $make-fragment := true()
let $display-root-namespace := true()
let $fragment := util:get-fragment-between($beginning-node, $ending-node, $make-fragment, $display-root-namespace)
let $node := util:parse($fragment)
return
    map{
        "@context": "http://iiif.io/api/presentation/2/context.jsonld",
        "@id": "http://scta.info/iiif/wdr-wettf15/list/107v",
        "@type": "sc:AnnotationList",
        "within": map {
        "@id": "http://scta.info/iiif/pp-sorb/layer/transcription",
        "@type": "sc:Layer",
        "label": "Diplomatic Transcription"

        },
        "resources": [
            map {
                "@type": "oa:Annotation",
                "@id": "http://scta.info/iiif/wdr-wettf15/annotation/transcription",
                "motivation": "sc:painting",
                "resource": map {
                    "@id": "http://scta.lombardpress.org/text/plaintext/wdrl1d1-qqsirr/wettf15/transcription",
                    "@type": "dctypes:Text",
                    "chars": $node/string(),
                    "format": "text/html"
                },
        "on": $canvasid

            }
        ]

    }
:)
