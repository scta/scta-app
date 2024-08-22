xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

declare namespace array = "http://www.w3.org/2005/xpath-functions/array";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";

declare option output:method "json";
declare option output:indent "yes";

declare option output:media-type "application/json";

                    
import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";

(: borrowed working code example from: 
 : 
 : https://xqueryfiddle.liberty-development.net/pPgCcoF
 : https://stackoverflow.com/questions/58783334/xml-to-json-how-to-reconstruct-the-order-of-nodes-after-conversion-to-json
 : 
 :  :)

(: this function removes pb cb and lb from the xml doc before converting to json
 : it's not ideal to be losing this data, but when elements occur within a word it is breaking the word into two pieces making it hard 
 : to get a correct word range count
 : 
 : an in a way we don't need lb, cb, pb info because we should know those from the word or word range that has been selected 
 : 
 : so far it seems to be working but its a little fragile
 : :)
declare function local:remove-lb($node as node()) as node() {
    typeswitch ($node)
        case element() return
            element { name($node) } {
                $node/@*,  (: Retain all attributes :)
                for $child in $node/node()
                return
                    if (matches($child/name(), '^(lb|cb|pb)$')) then ()
(:                    else if ($child instance of text() and $child/preceding-sibling::node()[1]/name() = 'lb') then:)
(:                        concat($child/preceding-sibling::text()[1], $child):)
                    else
                        local:remove-lb($child)
            }
        case text() return $node
        default return $node
};


declare function local:jsonify($nodes) {
    
    array {
        for $node in $nodes
        return
            typeswitch ($node)
                case document-node() return
                    map {
                        "node-type": "document-node",
                        "child-nodes": local:jsonify($node/node())
                    }
                case element() return 
                    map {
                        "node-type": "element",
                        "node-name": $node/name(),
                        "attributes": array {
                            for $attr in $node/@*
                            return
                                map { 
                                    "name": $attr/name(),
                                    "value": $attr/string()
                                }
                        },
                        "child-nodes": local:jsonify($node/node())
                    }
                case text() return
                    map {
                        "node-type": "text",
                        "value": $node
                    }
                default return
                    map { "type": "unknown", "node": $node }
    }
};



declare function local:getSparqlQuery($transcription_id as xs:string) as xs:string {
  let $query := xs:string('
  SELECT ?type ?item ?topLevelTranscription ?level ?order
  WHERE
  {
      <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/structureType> ?type .

      #option for top level collection expression
      OPTIONAL
      {
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/level> ?level .
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/hasStructureItem> ?item .
        ?item <http://scta.info/property/isTranscriptionOf> ?m .
        ?m <http://scta.info/property/isManifestationOf> ?e .
        ?e <http://scta.info/property/totalOrderNumber> ?order .
      }
      #option for non top level collection
      OPTIONAL
      {
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/hasStructureItem> ?item .
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/isPartOfTopLevelTranscription> ?topLevelTranscription .
        ?item <http://scta.info/property/isTranscriptionOf> ?m .
        ?m <http://scta.info/property/isManifestationOf> ?e .
        ?e <http://scta.info/property/totalOrderNumber> ?order .
      }
      # option for division or block
      OPTIONAL
      {
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/isPartOfStructureItem> ?item .
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/isPartOfTopLevelTranscription> ?topLevelTranscription .
        ?item <http://scta.info/property/isTranscriptionOf> ?m .
        ?m <http://scta.info/property/isManifestationOf> ?e .
        ?e <http://scta.info/property/totalOrderNumber> ?order .
      }
      #option for structureItem
      OPTIONAL
      {
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/isPartOfTopLevelTranscription> ?topLevelTranscription .
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/isTranscriptionOf> ?m .
        ?m <http://scta.info/property/isManifestationOf> ?e .
        ?e <http://scta.info/property/totalOrderNumber> ?order .
      }
  }
  ORDER BY ?order
    ')
    return $query
};


let $response-header := response:set-header("Access-Control-Allow-Origin", "*")

(: main query :)
let $transcription_id := request:get-parameter('transcriptionid', 'lectio1/critical/transcription')
let $show_quote := request:get-parameter('quote', 'true')
let $show_pct := request:get-parameter('pct', 'false')
let $format := request:get-parameter('format', 'json')




let $fragments := tokenize($transcription_id, "/")
let $expression_short_id := $fragments[1]
let $url := "http://sparql-docker.scta.info/ds/query?query=",
(: let $url := "http://localhost:3030/ds/query?query=", :)
$sparql := local:getSparqlQuery($transcription_id),
$encoded-sparql := encode-for-uri($sparql),

$sparql-result := http:send-request(
   <http:request href="{concat($url, $encoded-sparql)}" method="get">
      <http:header name="accept" value="application/xml"/>
   </http:request>
)



    for $result in $sparql-result//sparql:result
        let $level := $result/sparql:binding[@name="level"]/sparql:literal/text()
        let $type-array := fn:tokenize($result/sparql:binding[@name="type"]/sparql:uri/text(), "/")
        let $type := $type-array[last()]
        let $url-array :=
          if ($type != "structureItem") then
              fn:tokenize(substring-after($result/sparql:binding[@name="item"]/sparql:uri/text(), "/resource/"), "/")
            else
              fn:tokenize($transcription_id, "/")

        let $itemid := $url-array[1]
        let $fileid := if ($url-array = "critical") then $url-array[1] else concat($url-array[2], "_", $url-array[1])
        let $url-cid-array := fn:tokenize(substring-after($result/sparql:binding[@name="topLevelTranscription"]/sparql:uri/text(), "/resource/"), "/")
        let $cid := $url-cid-array[1]

        let $doc :=
          if ($level eq '1') then
            doc(concat('/db/apps/scta-data/', $expression_short_id, '/', $itemid, '/', $fileid, '.xml'))
          else if ($type eq "structureCollection") then
            doc(concat('/db/apps/scta-data/', $cid, '/', $itemid, '/', $fileid, '.xml'))
          else if ($type eq "structureItem") then
            doc(concat('/db/apps/scta-data/', $cid, '/', $itemid, '/', $fileid, '.xml'))
          else
            doc(concat('/db/apps/scta-data/', $cid, '/', $itemid, '/', $fileid, '.xml'))

        let $div :=
          if ($type eq "structureCollection") then
            $doc/tei:TEI/tei:text/tei:body/tei:div
          else if ($type eq "structureItem") then
            $doc/tei:TEI/tei:text/tei:body/tei:div
          else
            $doc/tei:TEI/tei:text/tei:body//*[@xml:id=$expression_short_id]

        let $cid := if ($level eq '1') then
                $expression_short_id
             else
                 $cid

        (: Remove all <lb> elements and concatenate text nodes :)
        let $cleanedDiv := local:remove-lb($div)
(:        let $cleanedDiv := $div:)
        
        let $jsondoc := local:jsonify($cleanedDiv)
        return $jsondoc


