xquery version "3.1";
declare namespace functx = "http://www.functx.com";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace http="http://expath.org/ns/http-client";


declare function local:files($before, $after, $owner, $repo, $access_token){

  let $url := "https://api.github.com/repos/" || $owner ||"/" || $repo || "/compare/" || $before ||"..." || $after || "?access_token=" || $access_token
  let $request := <http:request method="GET" href="{$url}" timeout="30"/>
  let $response := http:send-request($request)
  let $files := if ($response[1]/@status = "200") then
      let $json := parse-json(util:binary-to-string($response[2]))
      return $json?files?*
    else
      let $json := parse-json(util:binary-to-string($response[2]))
      return $json

  return

  for $file in $files
    let $url := "https://api.github.com/repos/" || $owner ||"/" || $repo || "/contents/" || $file?filename || "?ref=" || $after || "&amp;" || $access_token
    let $request := <http:request method="GET" href="{$url}" timeout="30"/>
    let $response := http:send-request($request)
    let $new-content := util:base64-decode(parse-json(util:binary-to-string($response[2]))?content)
    (: let $new-content := "<test><p>new content</p></test>" :)

    return
      <p>{xmldb:store('/db/apps/scta-data/plaoulcommentary/lectio34/', $file?filename, $new-content)}</p>




};
declare function local:log($before, $after, $owner, $repo, $pushed-at, $new_data, $access_token){

  let $url := "https://api.github.com/repos/" || $owner ||"/" || $repo || "/compare/" || $before ||"..." || $after || "?access_token=" || $access_token
  let $request := <http:request method="GET" href="{$url}" timeout="30"/>
  let $response := http:send-request($request)

  let $filename := "pushEvent-" || $pushed-at || ".xml"
  let $new-content := "<logs><log>Push completed for commit " || $after || " for " || $owner || "/" || $repo || "</log></logs>"
  (: let $new-content := $new_data :)
  return
      <p>{xmldb:store('/db/apps/logs/', $filename, $new-content)}</p>

};

let $post_data := request:get-data()
let $new_data := util:binary-to-string($post_data)
let $parsed_data := parse-json($new_data)
let $before := $parsed_data?before
let $after := $parsed_data?after
let $repo := $parsed_data?repository?name
let $owner := $parsed_data?repository?owner?name
let $pushed-at := $parsed_data?repository?pushed_at
let $access_token := "ADD ACCESS TOKEN HERE"
return
  <div>

    {local:files($before, $after, $owner, $repo, $access_token)}
    {local:log($before, $after, $owner, $repo, $pushed-at, $new_data, $access_token)}

  </div>
