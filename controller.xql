xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:controller external;
declare variable $exist:resource external;
declare variable $exist:prefix external;

(: handle a request like /iiif/pp-reims/search?q=fides :)
  if (starts-with($exist:path, '/iiif/')) then
    let $fragments := substring-after($exist:path, '/iiif/')
    let $manifestationid := substring-before($fragments, "/search")
    return
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/iiif/iiifsearch-with-paging.xq">
          <add-parameter name="manifestationid" value="{$manifestationid}"/>
        </forward>
      </dispatch>
  else if (starts-with($exist:path, '/iiif2/')) then
    let $fragments := substring-after($exist:path, '/iiif2/')
    let $codexid := substring-before($fragments, "/search")
    return
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/iiifsearch-with-paging-line-level-from-simpleXmlCoordinates2.xq">
          <add-parameter name="codex" value="{$codexid}"/>
        </forward>
      </dispatch>
  else if (starts-with($exist:path, '/document/')) then
    let $transcriptionid := substring-after($exist:path, '/document/')
    return
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/doc/constructor.xq">
          <add-parameter name="transcriptionid" value="{$transcriptionid}"/>
        </forward>
      </dispatch>
  else if (starts-with($exist:path, '/text/')) then
    let $filepath := substring-after($exist:path, '/text/')
    let $response-header := response:set-header("Access-Control-Allow-Origin", "*")
    return

      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/../scta-data/{$filepath}">
        </forward>
      </dispatch>
  else if (starts-with($exist:path, '/csv/')) then
    let $transcriptionid := substring-after($exist:path, '/csv/')
    return
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/doc/csv.xq">
          <add-parameter name="transcriptionid" value="{$transcriptionid}"/>
        </forward>
      </dispatch>
  else if (starts-with($exist:path, '/search/author/')) then
    let $fragments := tokenize(substring-after($exist:path, '/search/author/'), '/')
    let $authorid := $fragments[1]
    (: let $query := $fragments[2] :)
    let $query := request:get-parameter('query', 'quod')
    return
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/search/search-text-by-author.xq">
          <add-parameter name="authorid" value="{$authorid}"/>
          <set-attribute name="query" value="{$query}"/>
        </forward>
      </dispatch>
  else if (starts-with($exist:path, '/search/expressiontype/')) then
    let $fragments := tokenize(substring-after($exist:path, '/search/expressiontype/'), '/')
    let $expression_type_id := $fragments[1]
    (: let $query := $fragments[2] :)
    let $query := request:get-parameter('query', 'quod')
    return
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/search/search-text-by-expressiontype.xq">
          <add-parameter name="expression_type_id" value="{$expression_type_id}"/>
          <set-attribute name="query" value="{$query}"/>
        </forward>
      </dispatch>
    else if (starts-with($exist:path, '/search/workgroup/')) then
      let $fragments := tokenize(substring-after($exist:path, '/search/workgroup/'), '/')
      let $workGroupId := $fragments[1]
      (: let $query := $fragments[2] :)
      let $query := request:get-parameter('query', 'quod')
      return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
          <forward url="{$exist:controller}/search/search-text-by-workgroupid.xq">
            <add-parameter name="workGroupId" value="{$workGroupId}"/>
            <set-attribute name="query" value="{$query}"/>
          </forward>
        </dispatch>
  else if (starts-with($exist:path, '/search/expression/')) then
    let $fragments := tokenize(substring-after($exist:path, '/search/expression/'), '/')
    let $expressionid := $fragments[1]
    (: let $query := $fragments[2] :)
    let $query := request:get-parameter('query', 'quod')
    return
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/search/search-text-by-expressionid.xq">
          <add-parameter name="expressionid" value="{$expressionid}"/>
          <set-attribute name="query" value="{$query}"/>
        </forward>
      </dispatch>
  (: let all other requests through :)
  else
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
      <cache-control cache="no"/>
    </ignore>
