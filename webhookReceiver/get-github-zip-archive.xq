xquery version "3.1";

module namespace gitarc="http://joewiz.org/ns/xquery/gitarc";

import module namespace hd = "http://joewiz.org/ns/xquery/http-download" at "http-download.xqm";
import module namespace unzip = "http://joewiz.org/ns/xquery/unzip" at "unzip.xqm";

declare function local:download-and-unpack-zip-archive($archive-url as xs:string, $destination as xs:string) as xs:string {
    let $download-temp-folder :=
        if (xmldb:collection-available("/db/http-download-temp")) then
            "/db/apps/scta-data/http-download-temp"
        else
            xmldb:create-collection("/db/apps/scta-data", "http-download-temp")
    let $downloaded-file := hd:download($archive-url, $download-temp-folder)
    let $unzip := unzip:unzip($downloaded-file, $destination)
    let $cleanup := xmldb:remove("/db/apps/scta-data/http-download-temp")
    return
        tokenize($downloaded-file, "/")[. ne ''][last()] => substring-before(".zip")
};

declare function gitarc:get-github-archive($archive-url, $parent-collection, $destination-collection-name) {
    let $zip-collection-name := local:download-and-unpack-zip-archive($archive-url, $parent-collection)
    let $zip-collection := $parent-collection || "/" || $zip-collection-name
    let $rename := xmldb:rename($zip-collection, $destination-collection-name)
    return
        <result>Successfully downloaded { $archive-url } to { $parent-collection || "/" || $destination-collection-name }</result>
};

(:let $archive-url := "https://github.com/scta-texts/summahalensis/archive/master.zip":)
(:let $destination := "/db/apps/scta-data/test/test":)
(:let $destination-collection-name := "summahalensis":)
(:return:)
(:    gitarc:get-github-archive($archive-url, $destination, $destination-collection-name):)
