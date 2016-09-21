xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $id {request:get-parameter('id', '')};

(:
if(request:get-attribute("org.exist.demo.login.user")) then
    (xmldb:remove('/db/apps/srophe-forms/data/places/tei', concat(tokenize($id,'/')[last()],'.xml')),
    response:redirect-to(xs:anyURI('../browse-places.html')))
else 'You do not have permission to delet this record'
:)
    (xmldb:remove('/db/apps/srophe-forms/data/places/tei', concat(tokenize($id,'/')[last()],'.xml')),
    response:redirect-to(xs:anyURI('../browse.html?_cache=no')))
