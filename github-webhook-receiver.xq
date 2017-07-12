(: xquery version "3.1";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";


declare option output:method "json";
declare option output:media-type "application/json";


import module namespace response = "http://exist-db.org/xquery/response";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace http = "http://expath.org/ns/http-client" at "/http-client/http-client.xq";
(: set response header :)
(:
declare function local:log($json as array(*)) {
    <table>
    {
        for $entry in $json?*
        let $commit := $entry?commit
        return
            <tr>
                <td>{$commit?committer?date}</td>
                <td>{$commit?committer?name}</td>
                <td>{$commit?message}</td>
            </tr>
    }
    </table>
};

let $response-header := response:set-header("Access-Control-Allow-Origin", "*")

let $post_data := request:get-data()
let $test := parse-json($post_data)
return
  local:log($test) :) :)

xquery version "3.1";
declare namespace functx = "http://www.functx.com";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
(: declare option output:method "json";
declare option output:media-type "application/json"; :)
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace http="http://expath.org/ns/http-client";


(: declare option exist:serialize "method=xml media-type=text/xml indent=yes"; :)
declare function local:log($json as array(*)) {
    <table>
    {
        for $entry in $json?*
        let $commit := $entry?commit
        return
            <tr>
                <td>{$commit?committer?date}</td>
                <td>{$commit?committer?name}</td>
                <td>{$commit?message}</td>
            </tr>
    }
    </table>
};
declare function local:files($before, $after, $owner, $repo){

  let $url := "https://api.github.com/repos/" || $owner ||"/" || $repo || "/compare/" || $before ||"..." || $after || "?access_token=" || fn:environment-variable("GITHUB_ACCESS_TOKEN")
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
  let $url := "https://api.github.com/repos/" || $owner ||"/" || $repo || "/contents/" || $file?filename || "?ref=" || $after || "&amp;" || fn:environment-variable("GITHUB_ACCESS_TOKEN")
    let $request := <http:request method="GET" href="{$url}" timeout="30"/>
    let $response := http:send-request($request)
    let $new-content := util:base64-decode(parse-json(util:binary-to-string($response[2]))?content)
    (: let $new-content := "<test><p>new content</p></test>" :)

    return
      <p>{xmldb:store('/db/apps/scta-data/plaoulcommentary/lectio34/', $file?filename, $new-content)}</p>


};
declare function local:lognew($before, $after, $owner, $repo, $pushed-at){

  let $url := "https://api.github.com/repos/" || $owner ||"/" || $repo || "/compare/" || $before ||"..." || $after || "?access_token=" || fn:environment-variable("GITHUB_ACCESS_TOKEN")
  let $request := <http:request method="GET" href="{$url}" timeout="30"/>
  let $response := http:send-request($request)
  let $files := if ($response[1]/@status = "200") then
      let $json := parse-json(util:binary-to-string($response[2]))
      return $json?files?*
    else
      let $json := parse-json(util:binary-to-string($response[2]))
      return $json



  let $filename := "pushEvent-" || $pushed-at || ".xml"
  let $new-content := "<logs><log>Push completed for commit " || $after || " for " || $owner || "/" || $repo || "</log></logs>"
  return
      <p>{xmldb:store('/db/apps/logs/', $filename, $new-content)}</p>

};
declare function local:comparison($json as map(*)) {

  <table>
    <h1>Modified</h1>
    <p>Before: {$json?before}</p>
    <p>After: {$json?after}</p>
  </table>
};
declare function local:modified($json as map(*)) {

  <table>
    <h1>Modified</h1>
  {
        for $entry in $json?commits?*
        return
          for $modified in $entry?modified?*
          return
          <tr>
              <td>{$modified}</td>
          </tr>
          }
        </table>
};
declare function local:added($json as map(*)) {

  <table>
    <h1>Added</h1>
  {
        for $entry in $json?commits?*
        return
          for $added in $entry?added?*
          return
          <tr>
              <td>{$added}</td>
          </tr>
          }
        </table>
};
declare function local:deleted($json as map(*)) {

  <table>
    <h2>Deleted</h2>
  {
        for $entry in $json?commits?*
        return
          for $deleted in $entry?deleted?*
          return
          <tr>
            <td>{$deleted}</td>
          </tr>
          }
        </table>
};
let $url :=
"https://api.github.com/repos/eXist-db/exist/commits?since=2015-01-01T00:00:00Z"
let $request := <http:request method="GET" href="{$url}" timeout="30"/>
let $response := http:send-request($request)
let $post_data := request:get-data()
let $new_data := util:binary-to-string($post_data)
let $parsed_data := parse-json($new_data)
let $before := $parsed_data?before
let $after := $parsed_data?after
let $repo := $parsed_data?repository?name
let $owner := $parsed_data?repository?owner?name
let $pushed-at := $parsed_data?repository?pushed_at
return
    (: if ($response[1]/@status = "200") then :)
        (: local:log(parse-json(util:binary-to-string($post_data[1]))) :)
    (: else
        () :)
        (: <p>{local:log(parse-json(util:binary-to-string($response[2])))}</p> :)

        <div>
            {local:files($before, $after, $owner, $repo)}
          {local:lognew($before, $after, $owner, $repo, $pushed-at)}
          </div>



        (: <p>{local:log(parse-json($post_data))}</p> :)
        (: <p>{functx:atomic-type(parse-json($post_data[1]))}</p> :)
