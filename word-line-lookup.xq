xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare option output:method "json";
declare option output:media-type "application/json";

import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";

(: remove punctuation to avoid word miss counts; &$182; replaces pilcrows; other symbolos could be added here in order to clear these out. :)
declare function local:removePunctation($string) {
    let $clean := replace($string, '\s+([^\p{L}|\p{N}|\p{P}]+)', '$1')
    let $clean2 := replace($clean, '[\s/&#182;]+', ' ')
    return $clean2
};


declare function local:getSparqlQuery($tid) as xs:string {
    let $query := xs:string("
        SELECT ?path
        WHERE
        {
            <" || $tid || "> <http://scta.info/property/hasDocument> ?path . 
        }
        ")
        return $query
    };


declare function local:recurse($node){
    for $child in $node/node()
        return 
            local:render($child)
};

declare function local:render($node){
    typeswitch($node)
        case text() return concat(local:removePunctation($node), ' ')
        case element(tei:p) return <p>{local:recurse($node)}</p>
        case element(tei:title) return local:recurse($node)
        case element(tei:name) return local:recurse($node)
        case element(tei:rdg) return ()
        case element(tei:orig) return ()
        case element(tei:bibl) return ()
        case element (tei:note) return ()
        case element (tei:lb) return(<span n="{$node/@n}" type="line" break="{$node/@break}" page="{$node/preceding::tei:pb[1]/@n}"/>)
        case element (tei:pb) return(<span n="{$node/@n}" type="page"/>)
        default return local:recurse($node)
};

declare function local:getTokenPosition($node, $precedingpb as xs:string){
    let $totalNodes := $node//node()
        
    let $totalTokens := count(tokenize(string-join($node//text()//normalize-space(), ' '), ' '))
    
    for $token at $position in $totalNodes
    let $list := 
                let $lineTextTokens := tokenize($totalNodes[$position])
                let $pbNum := if ($totalNodes[$position - 1]/@page) then ($totalNodes[$position - 1]/@page) else ($precedingpb)
                let $lbNum := if ($totalNodes[$position - 1]/@n) then ($totalNodes[$position - 1]/@n) else ($totalNodes[$position + 1]/@n - 1)
                where (not($token/@n))
                for $word at $position2 in $lineTextTokens
                    (: this conditions makes sure the word is not a null value by checking the break status; determines if the first word on this line should be counted as a new word or is actually the second half of the word started on the preceding line                :)
                    where $word and (not($totalNodes[$position - 1]/@break='no' and $position2 eq 1))
                        return (
                            map {
                            "line": number($lbNum),   
                            "precedingpb": $pbNum,
                            "word": $word,
                            "wordLinePosition": $position2,
                            "wordLineTotal": count($lineTextTokens)
                        }
                    )
            return $list
};

let $response-header := response:set-header("Access-Control-Allow-Origin", "*")
let $tid := request:get-parameter('tid', 'http://scta.info/resource/pgb1q1-sepicl/lon/transcription')
let $sparql := local:getSparqlQuery($tid)
let $encoded-sparql := encode-for-uri($sparql)
let $url := "http://sparql-docker.scta.info/ds/query?query="
let $sparql-result := http:send-request(
   <http:request href="{concat($url, $encoded-sparql)}" method="get">
      <http:header name="accept" value="application/xml"/>
   </http:request>
)
let $path := $sparql-result//sparql:result[1]/sparql:binding[@name="path"]/sparql:uri/text()
let $pathFragments := tokenize(tokenize($path, "/scta-texts/")[2], '/')
let $fileName := tokenize($pathFragments[5], "#")[1]
let $pxmlid := tokenize($pathFragments[5], "#")[2]
let $docpath := "/db/apps/scta-data/" || $pathFragments[1] || "/" || $pathFragments[4] || "/" || $fileName
let $transcription := doc($docpath)//tei:p[@xml:id=$pxmlid]
let $precedingpb := doc($docpath)//tei:p[@xml:id=$pxmlid]/preceding::tei:pb[1]/@n
(:return local:render($transcription):)
return local:getTokenPosition(local:render($transcription), $precedingpb)
(: return $docpath:)