xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace jssearchutils = 'http://xquery.scta.info/json-search-utils' at 'json-search-utils.xq';

declare option output:method "json";
declare option output:media-type "application/json";

import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";


declare function local:getSparqlQuery($workGroup_short_id) as xs:string {
    (: currently cannot get $expression_type_id passed into query string; so it is currently hard coded to librum1-prologus :)
    let $query := xs:string('
        SELECT ?item ?topLevelExpression
        WHERE
        {
            <http://scta.info/resource/' || $workGroup_short_id || '> <http://scta.info/property/hasExpression> ?topLevelExpression .
            ?topLevelExpression <http://scta.info/property/hasStructureItem> ?item .
        }
        ')
        return $query
    };


(: main query :)
let $response-header := response:set-header("Access-Control-Allow-Origin", "*")
let $workGroup_short_id := request:get-parameter('workGroupId', 'sententiae')
let $url := "http://sparql-docker.scta.info/ds/query?query=",
$sparql := local:getSparqlQuery($workGroup_short_id),
$encoded-sparql := encode-for-uri($sparql),

$sparql-result := http:send-request(
   <http:request href="{concat($url, $encoded-sparql)}" method="get">
      <http:header name="accept" value="application/xml"/>
   </http:request>
)


return 
    map {
    "results": 
    
        for $result in $sparql-result//sparql:result
        let $url-array := fn:tokenize($result/sparql:binding[@name="item"]/sparql:uri/text(), "/")
        let $itemid := $url-array[last()]
        let $url-cid-array := fn:tokenize($result/sparql:binding[@name="topLevelExpression"]/sparql:uri/text(), "/")
        let $cid := $url-cid-array[last()]
        
        let $transcription := doc(concat('/db/apps/scta-data/', $cid, '/', $itemid, '/transcriptions.xml'))/transcriptions/transcription[1]

    
        let $doc := if ($transcription) then 
                        concat('/db/apps/scta-data/', $cid, '/', $itemid, '/', $transcription)
                    else
                    concat('/db/apps/scta-data/', $cid, '/', $itemid, '/', $itemid, '.xml')

        let $query := request:get-parameter('query', 'potentia')
    
        let $hits := doc($doc)//tei:p[ft:query(., $query)]
    
        for $hit in $hits
        
            let $pid := $hit/@xml:id/string()
            order by ft:score($hit) descending
            return
                let $summarize := kwic:summarize($hit, <config width="100"/>)
                for $item at $index in $summarize
                let $precedingCount := jssearchutils:getTokenPosition(jssearchutils:render(kwic:expand($hit)), $index)
                let $getSummary := jssearchutils:render(kwic:expand($hit))
                
                return 
                    map{
                    "pid": $pid,
                    "index": $index,
                    "start": $precedingCount/start/text(),
                    "end": $precedingCount/end/text(),
                    "hit": normalize-space(jssearchutils:render(util:expand($item/span[@class='hi']))),
                    "previous": normalize-space(jssearchutils:render(util:expand($item/span[@class='previous']))),
                    "next": normalize-space(jssearchutils:render(util:expand($item/span[@class='following'])))
                }
        }
    
