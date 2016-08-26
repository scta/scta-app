xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:controller external;
declare variable $exist:resource external;
declare variable $exist:prefix external;

(: handle a request like /iiif/pp-reims/search?q=fides :)
  if (starts-with($exist:path, '/iiif/')) then
    let $fragments := tokenize(substring-after($exist:path, '/iiif/'), '/')
    let $full-msslug := $fragments[1]
    return
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/iiifsearch-with-paging.xq">
          <add-parameter name="full-msslug" value="{$full-msslug}"/>
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
  else if (starts-with($exist:path, '/search/author/')) then
    let $fragments := tokenize(substring-after($exist:path, '/search/author/'), '/')
    let $authorid := $fragments[1]
    let $query := $fragments[2]
    return
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/search/search-text-by-author.xq">
          <add-parameter name="authorid" value="{$authorid}"/>
          <add-parameter name="query" value="{$query}"/>
        </forward>
      </dispatch>
  else if (starts-with($exist:path, '/search/expressiontype/')) then
    let $fragments := tokenize(substring-after($exist:path, '/search/expressiontype/'), '/')
    let $expression_type_id := $fragments[1]
    let $query := $fragments[2]
    return
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/search/search-text-by-expressiontype.xq">
          <add-parameter name="expression_type_id" value="{$expression_type_id}"/>
          <add-parameter name="query" value="{$query}"/>
        </forward>
      </dispatch>
  else if (starts-with($exist:path, '/search/expression/')) then
    let $fragments := tokenize(substring-after($exist:path, '/search/expression/'), '/')
    let $expressionid := $fragments[1]
    let $query := $fragments[2]
    return
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/search/search-text-by-expressionid.xq">
          <add-parameter name="expressionid" value="{$expressionid}"/>
          <add-parameter name="query" value="{$query}"/>
        </forward>
      </dispatch>
  (: let all other requests through :)
  else
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
      <cache-control cache="no"/>
    </ignore>
