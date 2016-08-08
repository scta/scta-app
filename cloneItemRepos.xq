xquery version "3.0";

import module namespace git="http://exist-db.org/git";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace scta-property="http://scta.info/property/";
declare namespace scta-resource="http://scta.info/resource/";
declare namespace dc-terms="http://purl.org/dc/terms/";

declare function local:get-repo-profile($commentary-url as xs:string) {
    let $request := <http:request href="{$commentary-url}" method="get">
                        <http:header name="Accept" value="application/rdf+xml"/>
                    </http:request>
    let $response := http:send-request($request)
    let $header := $response[1]
    let $body := $response[2]
    let $commentary-id := $body/rdf:RDF/scta-resource:commentarius/@rdf:about
    let $item-ids := $body/rdf:RDF/scta-resource:commentarius/scta-property:hasItem/@rdf:resource
    return
        element result {
            element commentary-id {tokenize($commentary-id, '/')[position() = last() - 1]},
            element item-ids { $item-ids ! element item-id {tokenize(., '/')[last()] } }
        }
};

let $commentary-url := 'http://scta.info/text/graciliscommentary/commentary'
let $repo-profile := local:get-repo-profile($commentary-url)
let $commentary-id := $repo-profile/commentary-id
for $item-id in subsequence($repo-profile//item-id, 3, 1)
let $remotePath := concat('https://bitbucket.org/jeffreycwitt/', lower-case($item-id), '.git')
let $localPath := concat('/db/apps/scta/', $commentary-id, '/', $item-id, '/')
let $username := 'lbpuser'
let $password := 'plaoulRepo' 
return
    git:pull($remotePath, $localPath, $username, $password)

