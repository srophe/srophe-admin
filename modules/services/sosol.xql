xquery version "3.0";
(:~
 : SOSL OAuth and submission, will need to be broken out a bit. 
:)

import module namespace oauth="http://syriaca.org/oauth" at "oauth.xql";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace http="http://expath.org/ns/http-client";
declare namespace httpclient="http://exist-db.org/xquery/httpclient";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace json="http://www.json.org";
declare option exist:serialize "method=html5 media-type=text/html omit-xml-declaration=yes indent=yes";

(oauth:authenticate(),
<html lang="en">
  <head>
    <meta charset="utf-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/> 
    <title>Perseids submission</title>
    <link rel="stylesheet" type="text/css" href="/exist/apps/srophe/resources/css/bootstrap.min.css" />
    <link rel="stylesheet" type="text/css" href="/exist/apps/srophe/resources/css/main.css" />
  </head>
  <body>
   <div class="container" style="padding:5em 2em;">
    <div class="jumbotron">
    <h3>Congratulations! You are authenticated with Perseids</h3>
        <p>Please <a href="javascript:self.close()">re-submit</a> your record now that you are authenticated.</p>
    </div>
    </div>
    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script type="text/javascript" src="/exist/apps/srophe/resources/js/bootstrap.min.js"></script>
  </body>
</html>)