xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace console="http://exist-db.org/xquery/console";

declare option output:method "html5";
declare option output:media-type "text/html";

let $commentaryid := request:get-parameter('commentaryid', 'lombardsententia')
let $docs :=
    for $collection in xmldb:get-child-collections(concat('/db/apps/scta/', $commentaryid))

(: main query :)
for $collection in xmldb:get-child-collections(concat('/db/apps/scta/', $commentaryid))
        let $transcription := doc(concat('/db/apps/scta/', $commentaryid, '/', $collection, '/transcriptions.xml'))/transcriptions/transcription
        return
            if ($transcription) then
                (
                doc(concat('/db/apps/scta/', $commentaryid, '/', $collection, '/', $transcription))
                ,
                console:log(concat('transcription found: /db/apps/scta/', $commentaryid, '/', $collection, '/', $transcription))
                )
            else
                (
                doc(concat('/db/apps/scta/', $commentaryid, '/', $collection, '/', $collection, '.xml'))
                ,
                console:log(concat('use canonical: /db/apps/scta/', $commentaryid, '/', $collection, '/', $collection, '.xml'))
                )

let $hits := $docs//tei:quote
return
<div class="searchresults">
        <p>{count($hits)} quotes found</p>
        {
        for $hit in $hits
        let $pid := $hit/ancestor::tei:p/@xml:id/string()
        let $itemid := $hit/ancestor::tei:body/tei:div/@xml:id/string()
        let $itemtitle := $hit/preceding::tei:titleStmt/tei:title/string()
        let $bibl := $hit/following-sibling::tei:bibl

        return
            <div style="border-bottom: 1px dotted gray; margin-bottom: 3px; padding: 3px;">
            <h3>Quote from paragraph {$pid}, item {$itemid}, {$itemtitle}</h3>
            <p>{$hit}</p>
            <p style="font: 10px">{$bibl}</p>

            </div>
        }
    </div>
