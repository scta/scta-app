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
  (: let all other requests through :)
  else
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
      <cache-control cache="no"/>
    </ignore>