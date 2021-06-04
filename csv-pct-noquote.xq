xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare option exist:serialize "method=text media-type=text/plain";

import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";

declare function local:removePunctation($string, $show_pct) {
    let $clean := if ($show_pct eq 'true') then
        replace($string, '\s+([^\p{L}|\p{N}|\p{P}]+)', '$1')
    else
        replace($string, '[^\p{L}|\p{N}]+', ' ')
    let $clean2 := replace($clean, '\s+', ' ')
    return $clean2
};

declare function local:render($node, $show_quote, $show_pct) {
    typeswitch($node)
        case text() return $node
        case element(tei:div) return <div>{local:recurse($node, $show_quote, $show_pct)}</div>
        case element(tei:p) return <p>{local:recurse($node, $show_quote, $show_pct)}</p>
        case element(tei:quote) return if ($show_quote eq 'true') then if ($show_pct eq 'true') then <p>"{local:recurse($node, $show_quote, $show_pct)}"</p> else <p>{local:recurse($node, $show_quote, $show_pct)}</p>  else () 
        case element(tei:ref) return <p>{local:recurse($node, $show_quote, $show_pct)}</p>
        case element(tei:name) return <p>{local:recurse($node, $show_quote, $show_pct)}</p>
        case element(tei:rdg) return ()
        case element(tei:bibl) return ()
        case element (tei:note) return ()
        case element (tei:orig) return ()
        (: ignore corr elements except when they are inside a lemma :)
        case element (tei:corr) return if ($node[name(parent::*) eq 'lem']) then <p>{local:recurse($node, $show_quote, $show_pct)}</p> else ()
        case element (tei:del) return ()
        case element (tei:lb) return ()
        case element (tei:head) return ()
        default return local:recurse($node, $show_quote, $show_pct)
};

declare function local:recurse($node, $show_quote, $show_pct) {
    for $child in $node/node()
    return
        local:render($child, $show_quote, $show_pct)
};




declare function local:getSparqlQuery($transcription_id as xs:string) as xs:string {
  let $query := xs:string('
  SELECT ?item ?topLevelTranscription
  WHERE
  {
      {
          <' || $transcription_id || '> <http://scta.info/property/structureType> <http://scta.info/resource/structureItem> .
          BIND (<' || $transcription_id || '> as ?item)
      }
      UNION
          {
          <' || $transcription_id || '> <http://scta.info/property/isPartOfStructureItem> ?item .
          }
      UNION
      {
        <' || $transcription_id || '> <http://scta.info/property/isPartOfStructureBlock> ?block .
        ?block <http://scta.info/property/isPartOfStructureItem> ?item .
      }
      <' || $transcription_id || '> <http://scta.info/property/isPartOfTopLevelTranscription> ?topLevelTranscription .
      
  }
    ')
    return $query
};

let $response-header := response:set-header("Access-Control-Allow-Origin", "*")

(: main query :)
let $transcription_id := request:get-parameter('resourceid', 'http://scta.info/resource/l1-cpspfs/reims/transcription')
let $show_quote := request:get-parameter('quote', 'true')
let $show_pct := request:get-parameter('pct', 'true')
let $fragments := tokenize($transcription_id, "http://scta.info/resource/")
let $slug := $fragments[2]
let $pid := tokenize($slug, "/")[1]

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
        let $url-array := fn:tokenize(substring-after($result/sparql:binding[@name="item"]/sparql:uri/text(), "/resource/"), "/")
        let $itemid := $url-array[1]
        let $fileid := if ($url-array = "critical") then $url-array[1] else concat($url-array[2], "_", $url-array[1])
        let $url-cid-array := fn:tokenize(substring-after($result/sparql:binding[@name="topLevelTranscription"]/sparql:uri/text(), "/resource/"), "/")
        let $cid := $url-cid-array[1]

        let $doc := doc(concat('/db/apps/scta-data/', $cid, '/', $itemid, '/', $fileid, '.xml'))

(:        let $div := $doc/tei:TEI/tei:text/tei:body//*[@xml:id=$itemid]:)
(::)
(:        for $p in $div//tei:p[@xml:id=$pid]:)
        
        for $p in $doc/tei:TEI/tei:text/tei:body//*[@xml:id=$pid]

          let $nl := codepoints-to-string(10)
          let $text := local:render($p, $show_quote, $show_pct)
          let $textClean := local:removePunctation($text, $show_pct)
          let $id := if (boolean($p/@xml:id)) then
              $p/@xml:id
            else
              concat("tmp:", $cid, ":", generate-id($p))
          
          return

             $textClean
