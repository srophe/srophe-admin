xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
declare option exist:serialize "method=html media-type=text/html indent=no";

let $name := request:get-uploaded-file-name("fileUpload")
let $file := request:get-uploaded-file-data("fileUpload")
let $module-name := request:get-parameter('module', '')
let $uri-mod-name := if(ends-with($module-name,'s')) then
                        substring($module-name,1,string-length($module-name)-1)
                     else $module-name
let $uri := concat($global:base-uri, $uri-mod-name ,'/', substring-before($name,'.xml'))
let $user:= request:get-attribute("org.exist.demo.login.user")
let $user-name := if ($user) then sm:get-account-metadata($user, xs:anyURI('http://axschema.org/namePerson')) else xmldb:get-current-user()
let $collection-path as xs:anyURI := xs:anyURI($global:data-root || '/data/' || $module-name || '/tei')
return
<html>
    <head>
        <meta charset="utf-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Syriaca.org: The Syriac Reference Portal Admin Pages</title>
        <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
        <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />
        <meta name="DC.type" property="dc.type" content="Text" />
        <meta name="DC.isPartOf" property="dc.ispartof" content="Syriaca.org" />
        <link rel="shortcut icon" href="$srophe-shared/resources/img/syriaca.ico" />
        <link rel="stylesheet" type="text/css" href="$srophe-shared/resources/css/bootstrap.min.css" />
        <link rel="stylesheet" type="text/css" href="$srophe-shared/resources/css/main.css" />
        <link rel="stylesheet" type="text/css" href="$srophe-shared/resources/css/syriaca.css" />
        <link rel="stylesheet" type="text/css" href="$app-root/resources/css/style.css" />
        <!-- temporary until migrate to bootstrap 3.0 -->
        <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js">/**/</script>
    </head>
    <body>
    <!-- Fixed navbar -->
        <div class="navbar navbar-default navbar-fixed-top" role="navigation">
            <div class="container">
                <div class="navbar-header"><button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target=".navbar-collapse"><span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button><a class="navbar-brand" href="index.html"><img alt="Syriac.org: Spear" src="/exist/apps/srophe/resources/img/syriaca-logo.png" /> Administrative Pages
                    </a>
                </div>
                <div class="navbar-collapse collapse">
                    <ul class="nav navbar-nav">
                        <li><a href="../upload.html">Upload New Records</a>
                        </li>
                        <li><a href="../browse.html?_cache=no">Records</a>
                        </li>
                        <li><a href="../browse-comments.html">Comments</a>
                        </li>
                    </ul>
                    <ul class="nav navbar-nav pull-right">
                        <li style="padding-top:1em;"><span><a href="index.html?logout=true">admin<span class="glyphicon glyphicon-remove" aria-hidden="true"></span></a></span>
                        </li>
                    </ul>
                </div><!--/.nav-collapse -->
            </div>
        </div>
    <div id="main">
            <div id="content" class="container well well-white">
                     <div id="response">
                          {
                         try {(
                             <p style="display:none;">
                             {(xmldb:store($collection-path, xmldb:encode-uri($name), $file))}
                             </p>,
                             <h4>Upload complete!</h4>,
                             <p>Sub mod name: {$uri-mod-name}</p>,
                             <p class="indent">File <strong>{$name}</strong> has been saved to:
                             <strong>{substring-after($collection-path,'/srophe-data/')}</strong>.
                             </p>,
                             <p class="indent alert alert-info">Review record:
                             <a href="{concat('../review-rec.html?id=',$uri)}">{$uri}</a></p>
                            )}
                         catch * {(
                            <p class="bg-danger">{concat($err:code, ": ", $err:description)}</p>,
                            <p>{xmldb:get-current-user()}</p>
                            )}
                         }
                     </div>
            </div>
    </div>
    </body>
</html>