xquery version "3.1";
declare namespace new="http://new";
let $collection := collection('/db/apps/simpleXmlCoordinates')


    let $count := count($collection//new:line)
    return <div><count>{$count}</count></div>
    
