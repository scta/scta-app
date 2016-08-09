xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";


declare function local:getSparqlQuery($expression_id as xs:string) as xs:string {
  let $query := xs:string('
  SELECT ?type ?item ?topLevelExpression ?level
  WHERE
  {
      <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/structureType> ?type .
      OPTIONAL
      {
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/level> ?level .
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/hasStructureItem> ?item .
      }
      OPTIONAL
      {
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/hasStructureItem> ?item .
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/isPartOfTopLevelExpression> ?topLevelExpression .
      }
      OPTIONAL
      {
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/isPartOfStructureItem> ?item .
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/isPartOfTopLevelExpression> ?topLevelExpression .
      }
  }
    ')
    return $query
};

(: main query :)
let $expression_id := request:get-parameter('expressionid', 'plaoulcommentary')
let $url := "http://sparql-staging.scta.info/ds/query?query=",
$sparql := local:getSparqlQuery($expression_id),
$encoded-sparql := encode-for-uri($sparql),

$sparql-result := http:send-request(
   <http:request href="{concat($url, $encoded-sparql)}" method="get">
      <http:header name="accept" value="application/xml"/>
   </http:request>
)

return

  <TEI>
    {
      (: write conditional here to check, if expressionid is at above, at, or below the structureItem level :)
    for $result in $sparql-result//sparql:result
        let $level := $result/sparql:binding[@name="level"]/sparql:literal/text()
        let $type-array := fn:tokenize($result/sparql:binding[@name="type"]/sparql:uri/text(), "/")
        let $type := $type-array[last()]
        let $url-array := fn:tokenize($result/sparql:binding[@name="item"]/sparql:uri/text(), "/")
        let $itemid := $url-array[last()]
        let $url-cid-array := fn:tokenize($result/sparql:binding[@name="topLevelExpression"]/sparql:uri/text(), "/")
        let $cid := $url-cid-array[last()]

        let $doc :=
          if ($level eq '1') then
            doc(concat('/db/apps/scta-data/', $expression_id, '/', $itemid, '/', $itemid, '.xml'))
          else if ($type eq "structureCollection") then
            doc(concat('/db/apps/scta-data/', $cid, '/', $itemid, '/', $itemid, '.xml'))
          else if ($type eq "structureItem") then
            doc(concat('/db/apps/scta-data/', $cid, '/', $expression_id, '/', $expression_id, '.xml'))
          else
            doc(concat('/db/apps/scta-data/', $cid, '/', $itemid, '/', $itemid, '.xml'))

        let $div :=
          if ($type eq "structureCollection") then
            $doc/tei:TEI/tei:text/tei:body/tei:div
          else if ($type eq "structureItem") then
            $doc/tei:TEI/tei:text/tei:body/tei:div
          else
            $doc/tei:TEI/tei:text/tei:body//*[@xml:id=$expression_id]

          return
            $div
      }
  </TEI>
