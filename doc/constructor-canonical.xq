xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";

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
let $expression_id := request:get-parameter('eid', 'plaoulreportatio')
let $fragments := tokenize($expression_id, "/")
let $expression_short_id := $fragments[1]
let $url := "http://sparql-docker.scta.info/ds/query?query=",
(: let $url := "http://localhost:3030/ds/query?query=", :)
$sparql := local:getSparqlQuery($expression_id),
$encoded-sparql := encode-for-uri($sparql),
$sparql-result := http:send-request(
   <http:request href="{concat($url, $encoded-sparql)}" method="get">
      <http:header name="accept" value="application/xml"/>
   </http:request>
)
let $wikiDataId := if ($sparql-result//sparql:result[1]/sparql:binding[@name="wikiDataId"]/sparql:uri/text()) then $sparql-result//sparql:result[1]/sparql:binding[@name="wikiDataId"]/sparql:uri/text() else $sparql-result//sparql:result[1]/sparql:binding[@name="author"]/sparql:uri/text()
let $sctaAuthorId := $sparql-result//sparql:result[1]/sparql:binding[@name="author"]/sparql:uri/text()
let $datetime := current-dateTime()

return

  <TEI xmlns="http://www.tei-c.org/ns/1.0">
    <teiHeader>
      <fileDesc>
        <titleStmt>
          <title ref="http://scta.info/resource/{$expression_id}">{$sparql-result//sparql:result[1]/sparql:binding[@name="title"]/sparql:literal/text()}</title>
          <author ref="{$wikiDataId}">{$sparql-result//sparql:result[1]/sparql:binding[@name="authorTitle"]/sparql:literal/text()}</author>
        </titleStmt>
        <publicationStmt>
        <authority>SCTA</authority>
        <availability status="free">
          <p>Published under a <ref target="https://creativecommons.org/licenses/by-nc-sa/4.0/">Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)</ref></p>
        </availability>
        <date when="{$datetime}">Compilation created on {$datetime}</date>
      </publicationStmt>
        <seriesStmt>
            <title>Scholastic Commentaries and Texts Archive</title>
            <idno>{$expression_id}</idno>
            </seriesStmt>
        <sourceDesc>
          <editionStmt>
              <edition>Canonical Edition</edition>
              <editor>Canonical edition auto composed from divisions listed as canonical in the SCTA database; canonical represents the best version possessed the SCTA and the current time of compilation; for detailed metadata about the components used to create this compilation see <ref target="http://scta.info/resource/{$expression_id}">http://scta.info/resource/{$expression_id}</ref></editor>
          </editionStmt>
        </sourceDesc>
      </fileDesc>
    </teiHeader>
      <text>
        <body>

    {
      (: write conditional here to check, if expressionid is at above, at, or below the structureItem level :)
    for $result in $sparql-result//sparql:result
        let $level := $result/sparql:binding[@name="level"]/sparql:literal/text()
        let $type-array := fn:tokenize($result/sparql:binding[@name="type"]/sparql:uri/text(), "/")
        let $type := $type-array[last()]
        let $url-array :=
          if ($type != "structureItem") then
              fn:tokenize(substring-after($result/sparql:binding[@name="item"]/sparql:uri/text(), "/resource/"), "/")
            else
              fn:tokenize($expression_id, "/")

        let $itemid := $url-array[1]
        let $itemTitle := $result/sparql:binding[@name="itemTitle"]/sparql:literal/text()
        let $fileid := if ($url-array = "critical") then $url-array[1] else concat($url-array[2], "_", $url-array[1])
        let $url-cid-array := fn:tokenize(substring-after($result/sparql:binding[@name="topLevel"]/sparql:uri/text(), "/resource/"), "/")
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
          
          return
              
              <div xml:id="{$itemid}-wrapper">
              <head>{$itemTitle}</head>
              {$div}
              </div>
            

      }
      </body>
    </text>
  </TEI>
