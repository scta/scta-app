xquery version "3.0";

let $response-header := response:set-header("Access-Control-Allow-Origin", "*")
let $xmlurl := request:get-parameter('xmlurl', 'https://exist.scta.info/exist/apps/scta-app/text/wodehamordinatio/b1-d3-qun/b1-d3-qun.xml')
let $xsltarget := request:get-parameter('xslurl', 'xslt-lbpwebjs-main.xsl')
let $pathFragment := substring-after($xmlurl, 'https://exist.scta.info/exist/apps/scta-app/text/')
let $input := doc(concat("/db/apps/scta-data/", $pathFragment))
let $xsl := doc(concat("/db/apps/scta-app/", $xsltarget))


return
    if ($input) then (
    transform:stream-transform($input, $xsl, ())
    )
    else(error("file not found"))