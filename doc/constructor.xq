xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";


declare function local:getSparqlQuery($transcription_id as xs:string) as xs:string {
  let $query := xs:string('
  SELECT ?type ?item ?topLevelTranscription ?level
  WHERE
  {
      <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/structureType> ?type .

      #option for top level collection expression
      OPTIONAL
      {
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/level> ?level .
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/hasStructureItem> ?item .
      }
      #option for non top level collection
      OPTIONAL
      {
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/hasStructureItem> ?item .
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/isPartOfTopLevelTranscription> ?topLevelTranscription .
      }
      # option for division or block
      OPTIONAL
      {
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/isPartOfStructureItem> ?item .
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/isPartOfTopLevelTranscription> ?topLevelTranscription .
      }
      #option for structureItem
      OPTIONAL
      {
        <http://scta.info/resource/' || $transcription_id || '> <http://scta.info/property/isPartOfTopLevelTranscription> ?topLevelTranscription .
      }
  }
    ')
    return $query
};

(: main query :)
let $transcription_id := request:get-parameter('transcriptionid', 'plaoulcommentary/vat/transcription')
let $fragments := tokenize($transcription_id, "/")
let $expression_short_id := $fragments[1]
(: let $url := "http://sparql-staging.scta.info/ds/query?query=", :)
let $url := "http://localhost:3030/ds/query?query=",
$sparql := local:getSparqlQuery($transcription_id),
$encoded-sparql := encode-for-uri($sparql),

$sparql-result := http:send-request(
   <http:request href="{concat($url, $encoded-sparql)}" method="get">
      <http:header name="accept" value="application/xml"/>
   </http:request>
)

return

  <TEI xmlns="http://www.tei-c.org/ns/1.0">
    <teiHeader>
      <fileDesc>
        <titleStmt>
          <title>Auto constructed for http://scta.info/resoure/{$transcription_id}</title>
        </titleStmt>
        <publicationStmt>
          <p></p>
        </publicationStmt>
        <sourceDesc>
          <p></p>
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

          return
            $div

      }
      </body>
    </text>
  </TEI>
