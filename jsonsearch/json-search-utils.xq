xquery version "3.0";

module namespace _ = 'http://xquery.scta.info/json-search-utils';
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function _:recurse($node){
    for $child in $node/node()
        return 
            _:render($child)
};

declare function _:removePunctuation($string) {
    let $clean := replace($string, '\s+([^\p{L}|\p{N}|\p{P}]+)', '$1')
    let $clean2 := replace($clean, '[¶/\.,;:]', '')
    let $clean3 := replace($clean2, '\s+', ' ')
    return $clean3
};

declare function _:render($node){
    typeswitch($node)
        case text() return (_:removePunctuation($node))
        case element(tei:p) return <p>{_:recurse($node)}</p>
        case element(tei:title) return <em>{_:recurse($node)}</em>
        case element(tei:name) return <span style="font-variant: small-caps">{_:recurse($node)}</span>
        case element(exist:match) return <span style="background-color: yellow;">{_:recurse($node)}</span>
        case element(tei:quote) return (_:recurse($node))
        case element(tei:ref) return (_:recurse($node))
        case element (tei:lb) return if ($node[@break='no']) then <span class="noBreak"/> else ()
        case element(tei:rdg) return ()
        case element(tei:bibl) return ()
        case element (tei:note) return ()
        default return _:recurse($node)
};



declare function _:getTokenPosition($node, $index as xs:integer){
(:    for $hit in $node//span:)
    let $totalTokens := count(tokenize(string-join($node//text()//normalize-space(), ' '), ' '))
    let $followingTokens := count(tokenize(string-join($node//text()[preceding::span[@style='background-color: yellow;'][$index]]//normalize-space(), ' '), ' '))
    let $precedingNoBreaksBeforeStart := count($node//span[@class='noBreak'][following::span[@style='background-color: yellow;']])
    let $NoBreaksWithinHit := count($node//span[@class='noBreak'][parent::span[@style='background-color: yellow;']])
    let $hitTokens := count(tokenize(string-join($node//span[@style='background-color: yellow;'][$index]//text()//normalize-space(), ' '), ' '))
    let $precedingTokens := $totalTokens - $followingTokens
    let $start := ($precedingTokens - ($hitTokens - 1)) - $precedingNoBreaksBeforeStart
(:    let $end := $start + ($hitTokens - 1):)
    let $end := $precedingTokens - $precedingNoBreaksBeforeStart + $NoBreaksWithinHit
    return <result>
            <start>{$start}</start>
            <end>{$end}</end>
        </result>

};

declare function _:filter($node as node(), $mode as xs:string) as xs:string? {
  if ($node/parent::rdg or $node/parent::bibl or $node/parent::note) then 
      ()
  else if ($mode eq 'before') then 
      concat($node, ' ')
  else 
      concat(' ', $node)
};

