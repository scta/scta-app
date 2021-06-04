(: dbutil:scan to change permissions :)
xquery version "3.1";
import module namespace dbutil="http://exist-db.org/xquery/dbutil";
dbutil:scan(
    xs:anyURI("/db/apps/scta-data"), 
    function($col, $res) { 
        if ($res) then 
            (
                sm:chown($res, "scta-user"),
                sm:chgrp($res, "scta-group")
            )
        else 
            (
                sm:chown($col, "scta-user"),
                sm:chgrp($col, "scta-group"),
                sm:chmod($col, "rwxrwxr-x")
            )
    }
)