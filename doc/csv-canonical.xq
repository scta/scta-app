xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare option exist:serialize "method=text media-type=text/plain";
(:(:declare option output:method "json";:):)
(:(:declare option output:media-type "application/json";:):)

                    
import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";

(:declare function local:removePunctation($string) {:)
(:    let $clean := replace($string, '[^\p{L}|\p{N}]+', ' '):)
(:    let $clean2 := replace($clean, '\s+', ' '):)
(:    return $clean2:)
(:};:)
(::)
(:declare function local:render($node) {:)
(:    typeswitch($node):)
(:        case text() return concat(local:removePunctation($node), '  '):)
(:        case element(tei:p) return <p>{local:recurse($node)}</p>:)
(:        case element(tei:rdg) return ():)
(:        case element(tei:bibl) return ():)
(:        case element (tei:note) return ():)
(:        default return local:recurse($node):)
(:};:)
(::)
(:declare function local:recurse($node) {:)
(:    for $child in $node/node():)
(:    return:)
(:        local:render($child):)
(:};:)



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
        case element (tei:lb) return ()
        case element (tei:head) return ()
        default return local:recurse($node, $show_quote, $show_pct)
};

declare function local:recurse($node, $show_quote, $show_pct) {
    for $child in $node/node()
    return
        local:render($child, $show_quote, $show_pct)
};




declare function local:getSparqlQuery($expression_id as xs:string) as xs:string {
  let $query := xs:string('
  SELECT ?type ?item ?topLevelTranscription ?level ?author ?authorTitle ?title ?wikiDataId ?itemTitle 
  WHERE
  {
      <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/structureType> ?type .
      <http://scta.info/resource/' || $expression_id || '> <http://purl.org/dc/elements/1.1/title> ?title .

      #option for top level collection expression
      OPTIONAL
      {
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/level> ?level .
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/hasStructureItem> ?eitem .
        ?eitem <http://scta.info/property/longTitle> ?itemTitle .
        ?eitem <http://scta.info/property/hasCanonicalManifestation> ?mitem .
        ?mitem <http://scta.info/property/hasCanonicalTranscription> ?item .
        ?eitem <http://scta.info/property/totalOrderNumber>	?totalOrder .
        <http://scta.info/resource/' || $expression_id || '> <http://www.loc.gov/loc.terms/relators/AUT> ?author .
        ?author <http://purl.org/dc/elements/1.1/title> ?authorTitle .
      }
      #option for non top level collection
      OPTIONAL
      {
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/isPartOfTopLevelExpression> ?topLevel .
        ?topLevel <http://www.loc.gov/loc.terms/relators/AUT> ?author .
        ?author <http://purl.org/dc/elements/1.1/title> ?authorTitle .
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/hasStructureItem> ?eitem .
        ?eitem <http://scta.info/property/longTitle> ?itemTitle .
        ?eitem <http://scta.info/property/hasCanonicalManifestation> ?mitem .
        ?mitem <http://scta.info/property/hasCanonicalTranscription> ?item .
        ?eitem <http://scta.info/property/totalOrderNumber>	?totalOrder .
        
      }
      # option for division or block 
      OPTIONAL
      {
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/isPartOfStructureItem> ?eitem .
        ?eitem <http://scta.info/property/longTitle> ?itemTitle .
        ?eitem <http://scta.info/property/hasCanonicalManifestation> ?mitem .
        ?mitem <http://scta.info/property/hasCanonicalTranscription> ?item .
        ?eitem <http://scta.info/property/totalOrderNumber>	?totalOrder .
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/isPartOfTopLevelExpression> ?topLevel .
        ?topLevel <http://www.loc.gov/loc.terms/relators/AUT> ?author .
        ?author <http://purl.org/dc/elements/1.1/title> ?authorTitle .
      }
      # option for element
      OPTIONAL
      {
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/isPartOfStructureBlock> ?block .
        ?block <http://scta.info/property/isPartOfStructureItem> ?eitem .
        ?eitem <http://scta.info/property/longTitle> ?itemTitle .
        ?eitem <http://scta.info/property/hasCanonicalManifestation> ?mitem .
        ?mitem <http://scta.info/property/hasCanonicalTranscription> ?item .
        ?eitem <http://scta.info/property/totalOrderNumber>	?totalOrder .
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/isPartOfTopLevelExpression> ?topLevel .
        ?topLevel <http://www.loc.gov/loc.terms/relators/AUT> ?author .
        ?author <http://purl.org/dc/elements/1.1/title> ?authorTitle .
      }
      #option for structureItem
      OPTIONAL
      {
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/isPartOfTopLevelExpression> ?topLevel .
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/longTitle> ?itemTitle .
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/hasCanonicalManifestation> ?mitem .
        ?mitem <http://scta.info/property/hasCanonicalTranscription> ?item .
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/totalOrderNumber>	?totalOrder .
        ?topLevel <http://www.loc.gov/loc.terms/relators/AUT> ?author .
        ?author <http://purl.org/dc/elements/1.1/title> ?authorTitle .
      }
      OPTIONAL{
        ?author <http://www.w3.org/2002/07/owl#sameAs> ?wikiDataId .
        FILTER ( strstarts(str(?wikiDataId), "http://www.wikidata.org") ) .
      }
  }
  ORDER BY ?totalOrder
    ')
    return $query
};


let $response-header := response:set-header("Access-Control-Allow-Origin", "*")

(: main query :)
let $eid := request:get-parameter('eid', 'plaoulreportatio')
let $show_quote := request:get-parameter('quote', 'true')
let $show_pct := request:get-parameter('pct', 'false')
let $format := request:get-parameter('format', 'json')




let $url := "http://sparql-docker.scta.info/ds/query?query=",
(: let $url := "http://localhost:3030/ds/query?query=", :)
$sparql := local:getSparqlQuery($eid),
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
              fn:tokenize($eid, "/")

        let $itemid := $url-array[1]
        let $fileid := if ($url-array = "critical") then $url-array[1] else concat($url-array[2], "_", $url-array[1])
        let $url-cid-array := fn:tokenize(substring-after($result/sparql:binding[@name="topLevelTranscription"]/sparql:uri/text(), "/resource/"), "/")
        let $cid := $url-cid-array[1]

        let $doc :=
          if ($level eq '1') then
            doc(concat('/db/apps/scta-data/', $eid, '/', $itemid, '/', $fileid, '.xml'))
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
            $doc/tei:TEI/tei:text/tei:body//*[@xml:id=$eid]

        let $cid := if ($level eq '1') then
                $eid
             else
                 $cid

        for $p in $div//tei:p

          let $nl := codepoints-to-string(10)
(:          let $text := local:render($p):)
(:          let $textClean := local:removePunctation($text):)
          let $text := local:render($p, $show_quote, $show_pct)
          let $textClean := local:removePunctation($text, $show_pct)
          let $id := if (boolean($p/@xml:id)) then
              $p/@xml:id
            else
              concat("tmp:", $cid, ":", generate-id($p))

          return
              if ($format eq 'text') then
                  $textClean
              else
                  concat($id, ",", $textClean, ", ", $cid, $nl)
                
              
                  
