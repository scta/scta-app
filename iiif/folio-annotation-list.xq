xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

let $doc := doc('/db/apps/scta-data/plaoulcommentary/lectio2/lectio2.xml')
let $canvasid := "test"
let $beginning-node := $doc/tei:TEI//tei:cb[@ed="#V"][2]
let $ending-node := $doc/tei:TEI//tei:cb[@ed="#V"][3]
let $make-fragment := true()
let $display-root-namespace := true()
let $fragment := util:get-fragment-between($beginning-node, $ending-node, $make-fragment, $display-root-namespace)
let $node := util:parse($fragment)
return
    map{
        "@context": "http://iiif.io/api/presentation/2/context.jsonld",
        "@id": "http://scta.info/iiif/wdr-wettf15/list/107v",
        "@type": "sc:AnnotationList",
        "within": map {
        "@id": "http://scta.info/iiif/pp-sorb/layer/transcription",
        "@type": "sc:Layer",
        "label": "Diplomatic Transcription"
            
        },
        "resources": [
            map {
                "@type": "oa:Annotation",
                "@id": "http://scta.info/iiif/wdr-wettf15/annotation/transcription",
                "motivation": "sc:painting",
                "resource": map {
                    "@id": "http://scta.lombardpress.org/text/plaintext/wdrl1d1-qqsirr/wettf15/transcription",
                    "@type": "dctypes:Text",
                    "chars": $node/string(),
                    "format": "text/html"
                },
        "on": $canvasid
            
            }
        ]
            
    }
    

    
    
