xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
import module namespace response = "http://exist-db.org/xquery/response";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";


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


(: set response header :)

let $response-header := response:set-header("Access-Control-Allow-Origin", "*")

let $q := request:get-parameter('q', '')
let $searchuri := request:get-uri()
(: full-msslug should be able to be parsed from requesting url :)
let $full-msslug : = request:get-parameter('full-msslug', 'pp-sorb')
let $msslug := tokenize($full-msslug, '-')[last()]
let $commentaryslug := tokenize($full-msslug, '-')[1]

(:  this is temporary and should be replace by a sparql query or an mapping document in exist :)
let $commentaryid :=
    if ($commentaryslug eq 'pp')
        then "plaoulcommentary"
    else if ($commentaryslug = 'pg')
        then "graciliscommentary"
    else if ($commentaryslug = 'wdr')
        then "rothwellcommentary"
    else if ($commentaryslug = 'pl')
        then "lombardsententia"
    else if ($commentaryslug = 'aw')
        then "wodehamordinatio"
    else if ($commentaryslug = 'atv')
        then "vargascommentary"
    else if ($commentaryslug = 'nddm')
        then "dinkelsbuhllectura"
    else if ($commentaryslug = 'ta') 
        then "aquinasscriptum"
    else
        "plaoulcommentary"
(: end slug to id mapping :)

let $docs := if (collection(concat('/db/apps/scta-data/', $commentaryid))[contains(util:document-name(.), $msslug)])
                then
                collection(concat('/db/apps/scta-data/', $commentaryid))[contains(util:document-name(.), $msslug)]
                else
                collection(concat('/db/apps/scta-data/', $commentaryid))

let $start:= xs:integer(request:get-parameter("start", "1"))
let $records := xs:integer(request:get-parameter("records", "10"))
let $page := request:get-parameter("page","1")
let $allHits := $docs//tei:p[ft:query(., $q)]

let $firstPage := 1

let $startIndex :=
    if ($page != "all") then
        (xs:integer($page) - 1) * $records
    else
        0

let $lastPage :=
    if (count($allHits) mod $records = 0) then
        xs:integer(count($allHits) div $records)
    else
        (xs:integer(count($allHits) div $records)) + 1

let $nextPage :=
    if ($page != "all") then
        if (xs:integer($page) < $lastPage) then
            xs:integer($page) + 1
        else
            xs:integer($firstPage)
    else
        1

let $prevPage :=
    if ($page != "all") then
        if (xs:integer($page) > 1) then
            xs:integer($page) - 1
        else
            xs:integer($lastPage)
    else
        1


let $resultsUrl :=
        if ($page != "all") then
            concat($searchuri, "?q=", $q, "&amp;page=", $page)
        else
            concat($searchuri, "?q=", $q)


(: compute the limits for this page :)
let $start :=
        if ($page != "all") then
            (xs:integer($page)*$records) - ($records - 1)
        else
            $start


(: restrict the full set of matches to this subsequence :)
let $hits :=
        if ($page != "all") then
            subsequence($allHits,$start,$records)
        else
            $allHits

return

        map{
          "@context":"http://iiif.io/api/search/0/context.json",
          "@id": concat("http://exist.scta.info", $resultsUrl),
          "@type":"sc:AnnotationList",
          (: it would be best if the followin properties were only
          present when the page parameter is set to an integer but ignored if the search results
          are for all, but I currently can't figure out how to execute a condition here :)
          "within": map
          {
            "@id": concat("http://exist.scta.info", $searchuri, "?q=", $q),
            "@type": "sc:Layer",
            "total": count($allHits),
            "first": concat("http://exist.scta.info", $searchuri, "?q=", $q, "&amp;page=", $firstPage),
            "last": concat("http://exist.scta.info", $searchuri, "?q=", $q, "&amp;page=", $lastPage)
          },
          "next": concat("http://exist.scta.info", $searchuri, "?q=", $q, "&amp;page=", $nextPage),
          "prev": concat("http://exist.scta.info", $searchuri, "?q=", $q, "&amp;page=", $prevPage),
          "startIndex": $startIndex,




          "resources":
            for $hit in $hits
            (: ancestor was not working in $pid statement. but ancestor should work and is preferabl to preceding :)
            let $pid := $hit/@xml:id/string()
            let $msInitial := $hit/preceding::tei:witness[@n=$msslug]/@xml:id
            let $msInitialPointer := concat("#", $msInitial)
            let $itemid := $hit/ancestor::tei:body/tei:div/@xml:id/string()
            let $itemtitle := $hit/preceding::tei:titleStmt/tei:title/string()
            let $bibl := $hit/following-sibling::tei:bibl
            (: needs to make adjustments if hit occurs in zone 1 or 2 or 3, etc
            currently it just defaults to the first zone :)
            let $zone := $hit/preceding::tei:zone[@start=concat("#", $pid)][1]
            let $sctacanvasbase := concat("http://scta.info/iiif/", $full-msslug, "/canvas/")

            (:this is a real mess
            but I'm going to explain what's happening
            so that it can be refactored when I get help

            The canvas id is looking first to see if there is zone with coordinates; if so its going to use this to build an scta canvas id -- this needs to be altered to allow for holding library canvas ids

            Then it checks to see if there is a preceding column break or a preceding page break.
            If there is it then to check to see if the cb or pb element has a select attribute

            if it does it goes up to the witness with the corresponding xml:base and concats this value with the value of the @select attribute

            if there is not @select attribute it will create a default scta canvasid

            Finally if there is not preecding it needs to find the folio that it starts on.

            One way to do this is the find the following cb or pb element and then calculate back to the previous one.

            Right now its only doing the first step, and its only defaulting to scta canvasds.

            This may become obsolete now that I have adopted the practice of including a "startsOn" section in the front part of each document.

            But I have not done this is a widespread way yet, so it only work for a very few text and should therefore not be implemented yet.

            :)
            let $canvasid := if ($zone) then
                                concat($sctacanvasbase, $zone/parent::tei:surface/@n/string())
                            else if ($hit/preceding::tei:cb[@ed=$msInitialPointer][1]) then
                                if ($hit/preceding::tei:cb[@ed=$msInitialPointer][1]/@select) then
                                    concat($hit/preceding::tei:witness[@xml:id=substring-after($hit/preceding::tei:cb[@ed=$msInitialPointer][1]/@ed, "#")]/@xml:base, $hit/preceding::tei:cb[@ed=$msInitialPointer][1]/@select)
                                else
                                    concat($sctacanvasbase, $hit/preceding::tei:witness[@xml:id=substring-after($hit/preceding::tei:cb[1]/@ed, "#")], substring($hit/preceding::tei:cb[@ed=$msInitialPointer][1]/@n, 1, string-length($hit/preceding::tei:cb[1]/@n) - 1))
                            else if ($hit/preceding::tei:pb[@ed=$msInitialPointer][1]) then
                                if ($hit/preceding::tei:pb[@ed=$msInitialPointer][1]/@select) then
                                    concat($hit/preceding::tei:witness[@xml:id=substring-after($hit/preceding::tei:pb[@ed=$msInitialPointer][1]/@ed, "#")]/@xml:base, $hit/preceding::tei:pb[@ed=$msInitialPointer][1]/@select)
                                else
                                    concat($sctacanvasbase, substring-after($hit/preceding::tei:pb[@ed=$msInitialPointer][1]/@ed, "#"), $hit/preceding::tei:pb[@ed=$msInitialPointer][1]/@n)


                            (: below steps need work :)
                            else if ($hit/following::tei:cb[@ed=$msInitialPointer][1]) then
                                (: but this will be 1 on off                                :)
                                (: need a function that can calculate previous folio :)
                                concat($sctacanvasbase, substring-after($hit/following::tei:cb[@ed=$msInitialPointer][1]/@ed, "#"), substring($hit/preceding::tei:cb[@ed=$msInitialPointer][1]/@n, 1, string-length($hit/preceding::tei:cb[1]/@n) - 1))
                            else if ($hit/following::tei:pb[@ed=$msInitialPointer][1]) then
                                (: but this will be 1 on off                                :)
                                (: need a function that can calculate previous folio :)
                                concat($sctacanvasbase, substring-after($hit/following::tei:pb[@ed=$msInitialPointer][1]/@ed, "#"), $hit/preceding::tei:pb[@ed=$msInitialPointer][1]/@n)
                            else
                                concat($sctacanvasbase, substring-after($hit/following::tei:pb[@ed=$msInitialPointer][1]/@ed, "#"), $hit/preceding::tei:pb[@ed=$msInitialPointer][1]/@n)


            let $ulx := $zone/@ulx
            let $uly := $zone/@uly
            let $lrx := $zone/@lrx
            let $lry := $zone/@lry
            let $width :=  $lrx - $ulx
            let $height := $lry - $uly
            let $on := if ($zone) then
                        concat($canvasid, "#xywh=", $ulx, ",", $uly, ",", $width, ",", $height)

                        else
                        $canvasid

            return

                    map {
                        "@id": concat("http://scta.info/iiif/", $full-msslug, "/search/annotations/", $pid),
                        "@type": "oa:Annotation",
                        "motivation": "sc:painting",
                        "resource":
                            map {
                                "@type": "cnt:ContentAsText",
                                "chars": local:render(util:expand($hit))
                            },
                        "on": $on
                    }



        }
