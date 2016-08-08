xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";


declare function local:getSparqlQuery($expression_id) as xs:string {
  let $query := xs:string('
    SELECT ?item ?topLevelExpression
    WHERE
    {
        <http://scta.info/resource/' || $expression_id || '> <http://scta.info/property/hasStructureItem> ?item .
        ?item <http://scta.info/property/isPartOfTopLevelExpression> ?topLevelExpression .
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
    for $result in $sparql-result//sparql:result
        let $url-array := fn:tokenize($result/sparql:binding[@name="item"]/sparql:uri/text(), "/")
        let $itemid := $url-array[last()]
        let $url-cid-array := fn:tokenize($result/sparql:binding[@name="topLevelExpression"]/sparql:uri/text(), "/")
        let $cid := $url-cid-array[last()]
        let $doc := doc(concat('/db/apps/scta-data/', $cid, '/', $itemid, '/', $itemid, '.xml'))
        let $div := $doc/tei:TEI/tei:text/tei:body/tei:div
        return
          $div
      }
  </TEI>
