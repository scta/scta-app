xquery version "3.0";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

import module namespace response = "http://exist-db.org/xquery/response";

import module namespace kwic="http://exist-db.org/xquery/kwic";
(:import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";:)
import module namespace jssearchutils = 'http://xquery.scta.info/json-search-utils' at 'json-search-utils.xq';

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

(: main :)
let $response-header := response:set-header("Access-Control-Allow-Origin", "*")

let $start-time := util:system-time()
let $q := request:get-parameter('query', '"potentia absoluta"~5')
let $commentaryid := request:get-parameter('expressionid', 'plaoulcommentary')
let $docs :=
    if ($commentaryid = "all") then
        for $commentaryid in xmldb:get-child-collections('/db/apps/scta-data/')
            for $itemid in xmldb:get-child-collections(concat('/db/apps/scta-data/', $commentaryid))
                let $transcription := doc(concat('/db/apps/scta-data/', $commentaryid, '/', $itemid, '/transcriptions.xml'))/transcriptions/transcription[1]
                return
                    if ($transcription) then
                        (
                        doc(concat('/db/apps/scta-data/', $commentaryid, '/', $itemid, '/', $transcription))
                        (: console:log(concat('transcription found: /db/apps/scta-data/', $commentaryid, '/', $itemid, '/', $transcription)) :)
                        )
                    else
                        (
                        doc(concat('/db/apps/scta-data/', $commentaryid, '/', $itemid, '/', $itemid, '.xml'))

(:                        console:log(concat('use canonical: /db/apps/scta-data/', $commentaryid, '/', $itemid, '/', $itemid, '.xml')):)
                        )
    else
        for $collection in xmldb:get-child-collections(concat('/db/apps/scta-data/', $commentaryid))
            let $transcription := doc(concat('/db/apps/scta-data/', $commentaryid, '/', $collection, '/transcriptions.xml'))/transcriptions/transcription[1]
            return
                if ($transcription) then
                    (
                    doc(concat('/db/apps/scta-data/', $commentaryid, '/', $collection, '/', $transcription))

(:                    console:log(concat('transcription found: /db/apps/scta-data/', $commentaryid, '/', $collection, '/', $transcription)):)
                    )
                else
                    (
                    doc(concat('/db/apps/scta-data/', $commentaryid, '/', $collection, '/', $collection, '.xml'))

(:                    console:log(concat('use canonical: /db/apps/scta-data/', $commentaryid, '/', $collection, '/', $collection, '.xml')):)
                    )

let $hits := $docs//tei:p[ft:query(., $q)]
let $end-time := util:system-time()
let $duration := $end-time - $start-time
let $minutes := minutes-from-duration($duration)
let $seconds := seconds-from-duration($duration)
return
    map {
        "count": count($hits),
        "query": $q,
        "results":
        for $hit in $hits
        let $pid := $hit/@xml:id/string()
        let $itemid := $hit/ancestor::tei:body/tei:div/@xml:id/string()
        let $itemtitle := $hit/preceding::tei:titleStmt/tei:title/string()
        
        
        
(:        local:render(util:expand($hit)):)
        order by ft:score($hit) descending
        
        return
(:            commented line should use third parameter to filter unwanted elements like rdg, note, and bible; but it is currently not working:)
(:            let $summarize := kwic:summarize($hit, <config width="100"/>, util:function(xs:QName("jssearchutils:filter"), 2)):)
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
