xquery version "1.0";

import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";

declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

declare option exist:serialize "method=html5 media-type=text/html";



declare function local:getSparqlQuery() as xs:string {
let $query := xs:string('
    SELECT ?item
    WHERE
    {
        ?item <http://scta.info/property/mentions> <http://scta.info/resource/person/Holcot> .
    }
    '
    )
    return $query
};

declare function local:getHtml($sparql-result as node()) {
    <html>
        <head>
            <title>SPARQLing XQuery</title>
        </head>
        <body>
            <ul>
            {
                for $result in $sparql-result//sparql:result

                    let $url-array := fn:tokenize($result/sparql:binding/sparql:uri/text(), "/"),
                    $itemid := $url-array[last()],
                    $cid : = $url-array[5]
                return
                    <li>{$cid}/{$itemid}</li>
            }
            </ul>
        </body>
    </html>
};

(: main query :)
let $url := "http://sparql-docker.scta.info/ds/query?query=",
$sparql := local:getSparqlQuery(),
$encoded-sparql := encode-for-uri($sparql),
$sparql-result := http:send-request(
   <http:request href="{concat($url, $encoded-sparql)}" method="get" >
      <http:header name="accept" value="application/xml"/>
   </http:request>
)
return local:getHtml($sparql-result[2])
(:return $sparql-result  :)
