xquery version "3.0";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

import module namespace response = "http://exist-db.org/xquery/response";

import module namespace kwic="http://exist-db.org/xquery/kwic";
(:import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";:)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";



declare function local:render($node) {
    typeswitch($node)
        case text() return concat($node, ' ')
        case element(tei:p) return <p>{local:recurse($node)}</p>
        case element(tei:title) return <em>{local:recurse($node)}</em>
        case element(tei:name) return <span style="font-variant: small-caps">{local:recurse($node)}</span>
        case element(exist:match) return <span style="background-color: yellow;">{local:recurse($node)}</span>
        case element(tei:rdg) return ()
        case element(tei:bibl) return ()
        case element (tei:note) return ()
        default return local:recurse($node)
};

declare function local:recurse($node) {
    for $child in $node/node()
    return
        local:render($child)
};

declare function local:getTokenPosition($node, $index as xs:integer){
(:    for $hit in $node//span:)
    let $totalTokens := count(tokenize(string-join($node//text()//normalize-space(), ' '), ' '))
    let $followingTokens := count(tokenize(string-join($node//text()[preceding::span[@style='background-color: yellow;'][$index]]//normalize-space(), ' '), ' '))
    let $hitTokens := count(tokenize(string-join($node//span[@style='background-color: yellow;'][$index]//text()//normalize-space(), ' '), ' '))
    let $precedingTokens := $totalTokens - $followingTokens
    let $start := $precedingTokens - ($hitTokens - 1)
(:    let $end := $start + ($hitTokens - 1):)
    let $end := $precedingTokens
    return <result>
            <start>{$start}</start>
            <end>{$end}</end>
        </result>

};


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
        let $summarize := kwic:summarize($hit, <config width="100"/>)
        
        
(:        local:render(util:expand($hit)):)
        order by ft:score($hit) descending
        return
            for $item at $index in $summarize
            let $precedingCount := local:getTokenPosition(local:render(kwic:expand($hit)), $index)
            let $getSummary := local:render(kwic:expand($hit))
            
            return 
                map{
                "pid": $pid,
                "index": $index,
                "start": $precedingCount/start/text(),
                "end": $precedingCount/end/text(),
                "hit": normalize-space(local:render(util:expand($item/span[@class='hi']))),
                "previous": normalize-space(local:render(util:expand($item/span[@class='previous']))),
                "next": normalize-space(local:render(util:expand($item/span[@class='following'])))
            }
    }
