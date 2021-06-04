xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=html media-type=text/html ident=no";

let $commentaryid := request:get-parameter('commentaryid', 'graciliscommentary')
let $itemid := request:get-parameter('itemid', 'pg-b1q2')
let $mid := request:get-parameter('mid', 'lon')

let $collection := concat("scta-data", "/", $commentaryid, "/", $itemid, "/", $mid, "_", $itemid, ".xml")
let $terms :=
    <terms>
        {
            util:index-keys(
                doc(concat("/db/apps/", $collection))//tei:p,
                "",
                function($key, $count) {
                    <term name="{$key}" count="{$count[1]}"
                        docs="{$count[2]}"/>
                }, -1, "lucene-index")
        }
    </terms>

let $sum := sum($terms//@count)
return
    <html>
        <head>

        </head>
        <body>
            <div style="background-color: lightgray; border-bottom: 2px solid black; padding: 10px;">
                <h1>SCTA Statistics</h1>
                <h2>Frequency analysis for {$collection}</h2>
                <h3>Total word count: {xs:decimal(xs:double($sum))}</h3>
            </div>
            <table style="padding: 10px;">
                <tr style="padding: 2px;">
                    <td style="font-weight: bold">Term</td>
                    <td style="font-weight: bold">Frequency</td>
                    <td style="font-weight: bold">Percentage</td>
                </tr>
                {
                    for $term in $terms//term

                        let $frequency := xs:integer($term/@count/string())
                        let $percentage := format-number(($term/@count div $sum), "%.00")
                        order by $frequency descending
                        return

                            <tr style="padding: 2px;">
                                <td>{$term/@name/string()}</td>
                                <td>{$frequency}</td>
                                <td>{$percentage}%</td>
                            </tr>
                }
                </table>
                </body>
                </html>
