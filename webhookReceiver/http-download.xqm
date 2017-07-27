xquery version "3.1";

module namespace hd="http://joewiz.org/ns/xquery/http-download";

import module namespace hc="http://expath.org/ns/http-client";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

(: downloads a file from a remote HTTP server at $file-url and save it to an eXist-db $collection.
 : we try hard to recognize XML files and save them with the correct mimetype so that eXist-db can 
 : efficiently index and query the files; if it doesn't appear to be XML, though, we just trust 
 : the response headers :)
declare function hd:download($file-url as xs:string, $collection as xs:string) as item()* {
    let $request := <hc:request href="{$file-url}" method="GET"/>
    let $response := hc:send-request($request)
    let $head := $response[1]
    
    (: These sample responses from EXPath HTTP client reveals where the response code, media-type, and filename can be found: 
    
        <hc:response xmlns:http="http://expath.org/ns/http-client" status="200"  message="OK">
            <hc:header name="connection"  value="close"/>
            <hc:header name="transfer-encoding"  value="chunked"/>
            <hc:header name="content-type"  value="application/zip"/>
            <hc:header name="content-disposition"  value="attachment; filename=xqjson-master.zip"/>
            <hc:header name="date"  value="Sat, 06 Jul 2013 05:59:04 GMT"/>
            <hc:body media-type="application/zip"/>
        </hc:response>
        
        <hc:response xmlns:http="http://expath.org/ns/http-client" status="200"  message="OK">
            <hc:header name="date"  value="Sat, 06 Jul 2013 06:26:34 GMT"/>
            <hc:header name="server"  value="GitHub.com"/>
            <hc:header name="content-type"  value="text/plain; charset=utf-8"/>
            <hc:header name="status"  value="200 OK"/>
            <hc:header name="content-disposition"  value="inline"/>
            <hc:header name="content-transfer-encoding"  value="binary"/>
            <hc:header name="etag"  value=""a6782b6125583f16632fa103a828fdd6""/>
            <hc:header name="vary"  value="Accept-Encoding"/>
            <hc:header name="cache-control"  value="private"/>
            <hc:header name="keep-alive"  value="timeout=10, max=50"/>
            <hc:header name="connection"  value="Keep-Alive"/>
            <hc:body media-type="text/plain"/>
        </hc:response>
    :)
    
    return
        (: check to ensure the remote server indicates success :)
        if ($head/@status = '200') then
            (: try to get the filename from the content-disposition header, otherwise construct from the $file-url :)
            let $filename := 
                if (contains($head/hc:header[@name='content-disposition']/@value, 'filename=')) then 
                    $head/hc:header[@name='content-disposition']/@value/substring-after(., 'filename=')
                else 
                    (: use whatever comes after the final / as the file name:)
                    replace($file-url, '^.*/([^/]*)$', '$1')
            (: override the stated media type if the file is known to be .xml :)
            let $media-type := $head/hc:body/@media-type
            let $mime-type := 
                if (ends-with($file-url, '.xml') and $media-type = 'text/plain') then
                    'application/xml'
                else 
                    $media-type
            (: if the file is XML and the payload is binary, we need convert the binary to string :)
            let $content-transfer-encoding := $head/hc:body[@name = 'content-transfer-encoding']/@value
            let $body := $response[2]
            let $file := 
                if (ends-with($file-url, '.xml') and $content-transfer-encoding = 'binary') then 
                    util:binary-to-string($body) 
                else 
                    $body
            return
                xmldb:store($collection, $filename, $file, $mime-type)
        else
            <error>
                <message>Oops, something went wrong:</message>
                {$head}
            </error>
};
