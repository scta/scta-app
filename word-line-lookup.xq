xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";


declare function local:recurse($node){
    for $child in $node/node()
        return 
            local:render($child)
};

declare function local:render($node){
    typeswitch($node)
        case text() return concat($node, ' ')
        case element(tei:p) return <p>{local:recurse($node)}</p>
        case element(tei:title) return local:recurse($node)
        case element(tei:name) return local:recurse($node)
        
        case element(tei:rdg) return ()
        case element(tei:orig) return ()
        case element(tei:bibl) return ()
        case element (tei:note) return ()
        case element (tei:lb) return(<span n="{$node/@n}"/>)
        case element (tei:pb) return(<span n="{$node/@n}"/>)
        default return local:recurse($node)
};

declare function local:getTokenPosition($node, $precedingpb as xs:string){
    let $totalNodes := $node//node()
    let $totalTokens := count(tokenize(string-join($node//text()//normalize-space(), ' '), ' '))
    
    for $token at $position in $totalNodes
    let $list := 
                let $lineTextTokens := tokenize($totalNodes[$position])
                let $pbNum := if ($totalNodes[$position - 2]/@n) then ($totalNodes[$position - 2]/@n) else ($precedingpb)
                let $lbNum := if ($totalNodes[$position - 1]/@n) then ($totalNodes[$position - 1]/@n) else ($totalNodes[$position + 1]/@n - 1)
                where (not($token/@n))
                for $word at $position2 in $lineTextTokens
                    where $word
                        return (
                            map {
                            "line": number($lbNum),   
                            "precedingpb": $pbNum,
                            "word": $word
(:                            "word-count": $position2:)
                        }
                    )
            return $list
};

let $transcription := doc('/db/apps/scta-data/graciliscommentary/pg-b1q1/lon_pg-b1q1.xml')//tei:p[@xml:id='pgb1q1-sepicl']
let $precedingpb := doc('/db/apps/scta-data/graciliscommentary/pg-b1q1/lon_pg-b1q1.xml')//tei:p[@xml:id='pgb1q1-sepicl']/preceding::tei:pb[1]/@n
(:return local:render($transcription):)
return local:getTokenPosition(local:render($transcription), $precedingpb)