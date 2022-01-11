xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace jssearchutils = 'http://xquery.scta.info/json-search-utils' at 'json-search-utils.xq';

declare option output:method "json";
declare option output:media-type "application/json";

import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";


declare function local:getSparqlQuery($wgid, $etid, $aid, $eid) as xs:string {
    (: currently cannot get $expression_type_id passed into query string; so it is currently hard coded to librum1-prologus :)
    let $etid_uri := "<http://scta.info/resource/" || $etid || ">"
    let $etid_query := if ($etid != '') then (
                "{
                  ?item <http://scta.info/property/expressionType>" || $etid_uri || " .
                  ?item <http://scta.info/property/structureType> <http://scta.info/resource/structureItem> .
                }
                UNION
                {
                  ?resource <http://scta.info/property/expressionType>" || $etid_uri || ".
                  ?resource <http://scta.info/property/isPartOfStructureItem> ?item .
                }
                UNION
                {
                  ?resource <http://scta.info/property/expressionType>" || $etid_uri || ".
                  ?resource <http://scta.info/property/hasStructureItem> ?item .
                }"
        )
    else (
       "" 
    )
    
    let $wgid_uri := "<http://scta.info/resource/" || $wgid || ">"
    let $wgid_query := if ($wgid != '') then 
        (
        $wgid_uri ||  "<http://scta.info/property/hasExpression> ?topLevelExpression .
        ?topLevelExpression <http://scta.info/property/hasStructureItem> ?item ."
    )
    else (
       "" 
    )
    
    let $aid_uri := "<http://scta.info/resource/" || $aid || ">"
    let $aid_query := if ($aid != '') then 
        (
        "?item <http://www.loc.gov/loc.terms/relators/AUT>" || $aid_uri || "."
        )
    else (
       "" 
    )
    let $eid_uri := "<http://scta.info/resource/" || $eid || ">"
    let $eid_query := if ($eid != '') then 
        (
        "{
            ?item <http://scta.info/property/isPartOfTopLevelExpression>" || $eid_uri || " .
            
         }
         UNION
         {
            " || $eid_uri || "<http://scta.info/property/structureType> <http://scta.info/resource/structureItem> .
            BIND(" || $eid_uri || " as ?item) .
            
         }"
        )
    else (
       "" 
    )
    let $query := xs:string("
        SELECT ?item ?topLevelExpression 
        WHERE{" 
        || $etid_query || ""
        || $wgid_query || ""
        || $aid_query || ""
        || $eid_query || "
        ?item <http://scta.info/property/isPartOfTopLevelExpression> ?topLevelExpression .
            
        }
        "
        )

        return $query
    };


(: main query :)
let $response-header := response:set-header("Access-Control-Allow-Origin", "*")
let $wgid := request:get-parameter('wgid', '')
let $eid := request:get-parameter('eid', '')
let $aid := request:get-parameter('aid', '')
let $etid := request:get-parameter('etid', '')
let $searchType := request:get-parameter('searchType', 'text')
let $url := "http://sparql-docker.scta.info/ds/query?query=",
$sparql := local:getSparqlQuery($wgid, $etid, $aid, $eid),
$encoded-sparql := encode-for-uri($sparql),

$sparql-result := http:send-request(
   <http:request href="{concat($url, $encoded-sparql)}" method="get">
      <http:header name="accept" value="application/xml"/>
   </http:request>
)

        let $combinedDocs := for $result in $sparql-result//sparql:result
            
            let $url-array := fn:tokenize($result/sparql:binding[@name="item"]/sparql:uri/text(), "/")
            let $itemid := $url-array[last()]
            let $url-cid-array := fn:tokenize($result/sparql:binding[@name="topLevelExpression"]/sparql:uri/text(), "/")
            let $cid := $url-cid-array[last()]
            
            let $transcription := doc(concat('/db/apps/scta-data/', $cid, '/', $itemid, '/transcriptions.xml'))/transcriptions/transcription[1]
    
        
            let $doc := if ($transcription) then 
                            concat('/db/apps/scta-data/', $cid, '/', $itemid, '/', $transcription)
                        else
                        concat('/db/apps/scta-data/', $cid, '/', $itemid, '/', $itemid, '.xml')
            return 
                <doc>{$doc}</doc>
    let $query := request:get-parameter('query', '')
    let $allHits := if ($query != '') 
        then (
            for $doc in $combinedDocs
                return 
                    if ($searchType eq "figure") then 
                        (
                            if ($query eq 'all') then(
                                doc($doc)//tei:figure
                            )   
                            else(
                                doc($doc)//tei:figure[ft:query(., $query)]
                            )
                        )
                        else (
                            doc($doc)//tei:p[ft:query(., $query)]
                        )
        )
        else ()
    
    let $hits := subsequence($allHits,1,1000)
return 
    
map {
    "totalCount": count($allHits),
    "results": 

        for $hit at $index in $hits

            let $pid := $hit/@xml:id/string()
            order by ft:score($hit) descending
            return
                if ($searchType eq "figure") then (
                    let $pid := $hit/@xml:id/string()
                    let $figureid := $hit/@xml:id/string()
                    let $itemtitle := $hit/preceding::tei:titleStmt/tei:title/string()
                    let $imgurl := $hit/tei:graphic/@url/string()
                    order by ft:score($hit) descending
                return 
                map{
                "id": $figureid,
                "pid": $pid,
                "index": $index,
                "imgurl": $imgurl
                }
                )
                else (
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
                )
                
            
        }
    
