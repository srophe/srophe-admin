xquery version "3.0";

(:~
 : SOSL OAuth and submission, will need to be broken out a bit.
:)
module namespace oauth="http://syriaca.org/oauth";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace http="http://expath.org/ns/http-client";
declare namespace httpclient="http://exist-db.org/xquery/httpclient";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace json="http://www.json.org";
declare option exist:serialize "method=xml media-type=text/xml indent=yes";
'testing gitigonre'