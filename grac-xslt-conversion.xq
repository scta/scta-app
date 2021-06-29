xquery version "3.0";

let $response-header := response:set-header("Access-Control-Allow-Origin", "*")
let $xsltarget := request:get-parameter('xslurl', 'xslt-modern-citations-2.xsl')
let $nameFilter := request:get-parameter('filter', 'false')

let $xsl := doc(concat("/db/apps/scta-app/", $xsltarget))

let $parameters := <parameters>
                    <param name="nameFilter" value="{$nameFilter}"/>
                </parameters>

return
    if ($xsl) then (
    transform:stream-transform($xsl, $xsl, $parameters)
    )
    else(error("file not found"))