xquery version "3.1";
declare namespace functx = "http://www.functx.com";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

import module namespace gitarc = "http://joewiz.org/ns/xquery/gitarc" at "get-github-zip-archive.xq";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace http="http://expath.org/ns/http-client";
import module namespace console="http://exist-db.org/xquery/console";


declare function local:topLevelCollectionQuery($shortid as xs:string){
    let $query := xs:string("
    SELECT ?top_level_expression_short_id
      WHERE
      {
          ?expression_item <http://scta.info/property/shortId> '" || $shortid || "' .
          ?expression_item <http://scta.info/property/isPartOfTopLevelExpression> ?topLevelExpression .
          ?topLevelExpression <http://scta.info/property/shortId> ?top_level_expression_short_id .
      }
    ")
    (: main query :)
    let $url := "http://sparql-docker.scta.info/ds/query?query=",
    $encoded-sparql := encode-for-uri($query),
    $sparql-result := http:send-request(
       <http:request href="{concat($url, $encoded-sparql)}" method="get">
          <http:header name="accept" value="application/xml"/>
       </http:request>
    )
    return
      (: this conditional assumes that if the no top level expression returns
      then short id given is already the top level expression collection :)
      if (count($sparql-result//sparql:result) eq 0) then
        let $test := $shortid
        return $test
      else
        for $result at $count in $sparql-result//sparql:result
          let $top_level_expression_short_id := $result//sparql:binding[@name="top_level_expression_short_id"]/sparql:literal/text()
          return $top_level_expression_short_id
  };



declare function local:replaceCollection($owner, $repo, $access_token) {
    (: these two lines could become their own function so that other apis like bitbucket could support it :)
    let $archive-url := gitarc:getArchiveUrl($owner, $repo, $access_token)
    let $shortid := $repo
    let $top_level_collection := local:topLevelCollectionQuery($shortid)
    let $parent-collection := if ($top_level_collection = $repo) then
        let $result := "/db/apps/scta-data/"
        return $result
      else
        let $result := "/db/apps/scta-data/" || $top_level_collection || "/"
        return $result

    return
        gitarc:get-github-archive($archive-url, $parent-collection, $repo)

};

declare function local:files($before, $after, $owner, $repo, $access_token){

  let $url := "https://api.github.com/repos/" || $owner ||"/" || $repo || "/compare/" || $before ||"..." || $after || "?access_token=" || $access_token
  let $request := <http:request method="GET" href="{$url}" timeout="1000"/>
  let $response := http:send-request($request)
  let $shortid := $repo
  let $top_level_collection := local:topLevelCollectionQuery($shortid)
  let $save-path := if ($top_level_collection = $repo) then
        let $result := "/db/apps/scta-data/" || $repo || "/"
        return $result
      else
        let $result := "/db/apps/scta-data/" || $top_level_collection || "/" || $repo || "/"
        return $result


  let $files := if ($response[1]/@status = "200") then
      let $json := parse-json(util:binary-to-string($response[2]))
      return $json?files?*
    else
      let $json := parse-json(util:binary-to-string($response[2]))
      return $json


    for $file in $files
      let $new-save-path := if (contains($file?filename, "/")) then
          let $additional-path := tokenize($file?filename, "/")[1]
          let $result := $save-path || $additional-path || "/"
          return $result
        else
          let $result := $save-path
          return $result
      let $new-file-name := if (contains($file?filename, "/")) then
          let $result := tokenize($file?filename, "/")[2]
          return $result
        else
          let $result := $file?filename
          return $result
      return
        if ($file?status = 'added' or $file?status = 'modified') then
          let $url := $file?contents_url || "&amp;access_token=" || $access_token
          (: let $url := "https://api.github.com/repos/" || $owner ||"/" || $repo || "/contents/" || $file?filename || "?ref=" || $after || "&amp;access_token=" || $access_token :)
          let $request := <http:request method="GET" href="{$url}" timeout="1000"/>
          let $response := http:send-request($request)
          let $new-content := util:base64-decode(parse-json(util:binary-to-string($response[2]))?content)
          return
            if (xmldb:collection-available($new-save-path)) then(
              <p>{$file?status}: {xmldb:store($new-save-path, $new-file-name, $new-content)}</p>
              (: <p>{$new-save-path} {$new-file-name} {$url}</p> :)
            )
            else(
              <div>
                (: <p>{xmldb:create-collection("/db/apps/scta-data/" || $top_level_collection, $new-save-path)}</p> :)
                (: <p>{$file?status}: {xmldb:store($new-save-path, $new-file-name, $new-content)}</p> :)
                <p>Collection not available: {$new-save-path} {$new-file-name}</p>
              </div>

            )
        else if ($file?status = 'removed') then
            <p>{$file?status}: {xmldb:remove($new-save-path, $new-file-name)}</p>
        else(
            <p>No files created, modified, or deleted</ p>
        )

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
let $access_token := environment-variable("GH_ACCESS_TOKEN")
let $branch := $parsed_data?ref
let $url := "https://api.github.com/repos/" || $owner ||"/" || $repo || "/compare/" || $before ||"..." || $after || "?access_token=" || $access_token

return
  if ($branch = "refs/heads/master") then
    <div>
      {local:replaceCollection($owner, $repo, $access_token)}
      {local:log($before, $after, $owner, $repo, $pushed-at, $new_data, $access_token)}
    </div>
    else
    <div>
      <p>{$url}</p>
      <p>Push Event Not on Master Branch, No Action Taken</p>
    </div>
