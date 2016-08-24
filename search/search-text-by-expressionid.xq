xquery version "3.0";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

(:import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";:)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";


declare option output:method "html5";
declare option output:media-type "text/html";

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

(: main :)
let $start-time := util:system-time()
let $q := request:get-parameter('query', '')
let $commentaryid := request:get-parameter('expressionid', 'plaoulcommentary')
let $docs :=
    if ($commentaryid = "all") then
        for $commentaryid in xmldb:get-child-collections('/db/apps/scta-data/')
            for $itemid in xmldb:get-child-collections(concat('/db/apps/scta-data/', $commentaryid))
                let $transcription := doc(concat('/db/apps/scta-data/', $commentaryid, '/', $itemid, '/transcriptions.xml'))/transcriptions/transcription
                return
                    if ($transcription) then
                        (
                        doc(concat('/db/apps/scta-data/', $commentaryid, '/', $itemid, '/', $transcription))
                        ,
                        console:log(concat('transcription found: /db/apps/scta-data/', $commentaryid, '/', $itemid, '/', $transcription))
                        )
                    else
                        (
                        doc(concat('/db/apps/scta-data/', $commentaryid, '/', $itemid, '/', $itemid, '.xml'))

(:                        console:log(concat('use canonical: /db/apps/scta-data/', $commentaryid, '/', $itemid, '/', $itemid, '.xml')):)
                        )
    else
        for $collection in xmldb:get-child-collections(concat('/db/apps/scta-data/', $commentaryid))
            let $transcription := doc(concat('/db/apps/scta-data/', $commentaryid, '/', $collection, '/transcriptions.xml'))/transcriptions/transcription
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
    <div class="searchresults">
        <p>{count($hits)} results found for '{$q}' in
            {
            string-join(
                (
                if ($minutes) then concat($minutes, ' minutes') else (),
                if ($seconds) then concat($seconds, ' seconds') else ()
                ),
                ', '
                )
            }
        </p>
        {
        for $hit in $hits
        let $pid := $hit/@xml:id/string()
        let $itemid := $hit/ancestor::tei:body/tei:div/@xml:id/string()
        let $itemtitle := $hit/preceding::tei:titleStmt/tei:title/string()

        return
            <div>
            <p><a href="/text/{$itemid}#{$pid}">{$itemtitle}, paragraph {$pid}</a></p>
            <p>{local:render(util:expand($hit))}</p>
            </div>
        }
    </div>
