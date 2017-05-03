xquery version "3.0";

module namespace app="http://syriaca.org/srophe-admin/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace comments="http://syriaca.org/srophe-admin/comments" at "comments.xql";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";

declare variable $app:id {request:get-parameter('id', '') cast as xs:string};
declare variable $app:sort {request:get-parameter('sort', 'alph') cast as xs:string};
declare variable $app:view {request:get-parameter('view', '') cast as xs:string};
declare variable $app:browse-type {request:get-parameter('type', 'places') cast as xs:string};
declare variable $app:collection-title {request:get-parameter('collection-title', '') cast as xs:string};
declare variable $app:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $app:perpage {request:get-parameter('perpage', 25) cast as xs:integer};

(:~
 : Get selected record.
 : $app:id record URI
:)
declare function app:get-rec($node as node(), $model as map(*)){
    map {"data" := collection($global:data-root)//tei:idno[@type='URI'][. = $app:id]/ancestor::tei:TEI}
};

(:~
 : Transform tei to html
 : @param $node data passed to transform
 : @depreicated
:)
declare function app:tei2html($nodes as node()*) {
    transform:transform($nodes, doc('../../srophe/resources/xsl/tei2html.xsl'),() )
};

(:~
 : Check current user, show username if loged in, otherwise 'Guest'
:)
declare function app:username($node as node(), $model as map(*)) {
    let $user:= request:get-attribute(concat($global:login-domain,'.user'))
    let $name :=
        if ($user) then 
            if(sm:get-account-metadata($user, xs:anyURI('http://axschema.org/namePerson')) != '') then
                sm:get-account-metadata($user, xs:anyURI('http://axschema.org/namePerson'))
            else xmldb:get-current-user()
        else 'Guest'
    return
    <span>
        {
        if ($name != 'Guest') then 
            <a href="?logout=true"><span class="glyphicon glyphicon-user" aria-hidden="true"/> {concat(' ',$name,' ')} <span class="glyphicon glyphicon-remove" aria-hidden="true"></span></a>
        else 
            <a href="#loginDialog" data-toggle="modal"><span class="glyphicon glyphicon-user" aria-hidden="true"/> Login </a>
        }
    </span>
};

(:
 : Logout function.
:)
declare function app:logout($node as node(), $model as map(*)) {
let $logout := request:get-parameter("logout", ())
let $user:= xmldb:get-current-user()
return
    if ($user!='guest') then <a href="index.html?logout=true"><i class="icon-remove-sign"></i></a>
    else ()
};

declare function app:get-collections-list($node as node(), $model as map(*)){
for $collection-title in distinct-values(collection($global:data-root)//tei:title[@level=('m','s')][parent::tei:titleStmt][not(ancestor::tei:TEI/descendant::tei:body/tei:biblStruct)])
order by $collection-title
return
    <option value="{$collection-title}">{$collection-title}</option>
};

(:~
 : Paging for browse pages.
:)
declare function app:paging($count){
let $perpage := 25
let $start := if($app:start) then $app:start else 1
let $total-result-count := $count
let $end :=
    if ($total-result-count lt $perpage) then
        $total-result-count
    else
        $start + $perpage
let $number-of-pages :=  xs:integer(ceiling($total-result-count div $perpage))
let $current-page := xs:integer(($start + $perpage) div $perpage)
(: get all parameters to pass to paging function:)
let $url-params := replace(request:get-query-string(), '&amp;start=\d+', '')
let $parameters :=  request:get-parameter-names()
return
    if($count gt $perpage) then
            (
                (: Show 'Previous' for all but the 1st page of results :)
                    if ($current-page = 1) then ()
                    else <li><a href="{concat('?', $url-params, '&amp;start=', $perpage * ($current-page - 2)) }">Prev</a></li>,

                (: Show links to each page of results :)
                let $max-pages-to-show := 8
                let $padding := xs:integer(round($max-pages-to-show div 2))
                let $start-page :=
                    if ($current-page le ($padding + 1)) then 1
                    else $current-page - $padding
                let $end-page :=
                    if ($number-of-pages le ($current-page + $padding)) then $number-of-pages
                    else $current-page + $padding - 1
                for $page in ($start-page to $end-page)
                let $newstart :=
                    if($page = 1) then 1
                    else $perpage * ($page - 1)
                return
                    (
                        if ($newstart eq $start) then (<li class="active"><a href="#" >{$page}</a></li>)
                        else <li><a href="{concat('?', $url-params, '&amp;start=', $newstart)}">{$page}</a></li>
                    ),
                (: Shows 'Next' for all but the last page of results :)
                if ($start + $perpage ge $total-result-count) then ()
                else <li><a href="{concat('?', $url-params, '&amp;start=', $start + $perpage)}">Next</a></li>
                )
else ()
};

declare function app:get-browse($node as node(), $model as map(*)){
let $recs :=
    if($app:collection-title != '') then
        if($app:view != '') then
            collection($global:data-root)//tei:title[. = $app:collection-title][parent::tei:titleStmt][ancestor::tei:TEI/descendant::tei:revisionDesc/@status = $app:view]
        else collection($global:data-root)//tei:title[. = $app:collection-title][parent::tei:titleStmt]
     else ()
return
    map {"browse-recs" := $recs}
};

declare function app:get-comments-browse($node as node(), $model as map(*)){
let $recs :=
        if($app:collection-title = 'person') then
            collection($global:comments-root || '/person')
        else if($app:collection-title = 'place') then collection($global:comments-root || '/place')
        else if($app:collection-title = 'manuscript') then collection($global:comments-root || '/manuscript')
        else if($app:collection-title = 'work') then collection($global:comments-root || '/work')
        else if($app:collection-title = 'bibl') then collection($global:comments-root || '/bibl')
        else collection($global:comments-root)
return
    map {"browse-comments" := $recs}
};

(:~
 : Browse collections.
 : $app:collection-title restrict by collection title in tei:titleStmt/tei:title[@level='m' or 's']
:)
declare function app:browse($node as node(), $model as map(*)){
if($app:collection-title != '') then
let $browse-count := count($model("browse-recs"))
return
<div class="section">
    <h2>{$app:collection-title} ({$browse-count})</h2>
    <table class="browse">
        <thead>
            <tr>
                <th class="status">Status</th>
                <th class="idno">ID</th>
                <th class="Title">Title
                <ul class="pagination nav nav-tabs pull-right">
                    {app:paging($browse-count)}
                        <li>
                         <div class="btn-group">
                             <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">View <span class="caret"/></button>
                                 <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}" id="published">All</a></li>
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;view=published" id="published">Published</a></li>
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;view=draft" id="draft">Draft</a></li>
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;view=deprecated" id="deprecated">Deprecated</a></li>
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;view=incomplete" id="incomplete">Incomplete</a></li>
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;view=underReview" id="underReview">Under Review</a></li>
                                 </ul>
                             </div>
                         </div>
                        </li>
                        <li>
                         <div class="btn-group">
                             <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">Sort <span class="caret"/></button>
                                 <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;sort=alpha" id="alpha">Alphabetical (Title)</a></li>
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;sort=num" id="num">ID No</a></li>
                                 </ul>
                             </div>
                         </div>
                        </li>
                </ul>
                </th>
            </tr>
        </thead>
        <tbody>
            {app:browse-list($node, $model)}
        </tbody>
    </table>
</div>
else ()
};

(:~
 : Browse records by collection
 : Records are pulled from srophe-data
:)
declare function app:browse-list($node, $model){
let $recs :=
        for $r in $model("browse-recs")/ancestor::tei:TEI
        let $title := $r/descendant::tei:title[parent::tei:titleStmt][@level = 'a']/text()
        let $id := $r/descendant::tei:publicationStmt/tei:idno[starts-with(.,'http://syriaca.org/')][1]/text()
        let $id := replace($id, '/tei','')
        let $num := xs:integer(tokenize($id,'/')[last()])
        let $sort := if($app:sort = 'num') then xs:integer($num) else $title[1]
        order by $sort ascending
        return $r
for $rec at $n in subsequence($recs, $app:start, 25)
let $title := $rec/descendant::tei:titleStmt/tei:title[@level = 'a']/node()
let $status := string($rec/descendant::tei:revisionDesc/@status)
let $id := replace($rec/descendant::tei:publicationStmt/tei:idno[starts-with(.,'http://syriaca.org/')][1]/text(),'/tei','')
let $num := tokenize($id,'/')[last()]
return
        <tr class="status {$status}">
            <td>{if($status = 'published') then
                <span class="label label-success">Published</span>
            else
                <span class="label label-warning">{$status}</span>}
            </td>
            <td>{string($num)}</td>
            <td><a href="review-rec.html?id={$id}">{$title}</a></td>
        </tr>
};

declare function app:browse-comments($node as node(), $model as map(*)){
let $browse-count := count($model("browse-comments"))
return
<div class="section">
    <h2>Browse {$app:collection-title} comments ({$browse-count})</h2>
    <table class="browse">
        <thead>
            <tr>
                <th class="status">Status</th>
                <th class="idno">ID</th>
                <th class="Title">Title
               <!-- <ul class="pagination nav nav-tabs pull-right">
                        <li>
                         <div class="btn-group">
                             <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">View <span class="caret"/></button>
                                 <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}" id="published">All</a></li>
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;view=published" id="published">Published</a></li>
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;view=draft" id="draft">Draft</a></li>
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;view=underReview" id="draft">Under Review</a></li>
                                 </ul>
                             </div>
                         </div>
                        </li>
                        <li>
                         <div class="btn-group">
                             <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">Sort <span class="caret"/></button>
                                 <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;sort=alpha" id="alpha">Alphabetical (Title)</a></li>
                                     <li role="presentation"><a role="menuitem" tabindex="-1" href="browse.html?collection-title={$app:collection-title}&amp;sort=num" id="num">ID No</a></li>
                                 </ul>
                             </div>
                         </div>
                        </li>
                </ul>   -->
                </th>
            </tr>
        </thead>
        <tbody>
        {
             for $rec in $model("browse-comments")
             let $title := $rec/atom:feed/atom:title[1]/node()
             let $id := substring-after($rec/atom:feed/atom:id,'comments:')
             let $num := tokenize($id,'/')[last()]
             let $file-path := concat(replace(replace($id,'http://syriaca.org/','/db/apps/srophe-forms/data/comments/'),'/tei',''),'.xml')
             let $status := doc($file-path)//atom:entry/atom:summary[starts-with(.,'approved : ')]
             let $status := if($status != '') then 'Approved' else 'Pending'
             let $sort := if($app:sort = 'num') then xs:integer($num) else $title[1]
             order by $sort ascending
             return
                 <tr class="status {$status}">
                     <td>{if($status = 'Approved') then
                         <span class="label label-success">Approved</span>
                     else
                         <span class="label label-warning">Pending</span>}
                     </td>
                     <td>{string($num)}</td>
                     <td><a href="comments.html?id={$id}">{$title}</a></td>
                 </tr>
            }
        </tbody>
    </table>
</div>
};

declare function app:rec-status($node as node(), $model as map(*)){
    if($app:id != '') then
        string($model("data")/descendant::tei:revisionDesc/@status)
    else ()
};

(:~
    Dashboard of record administrative functions
    View record on dev
    Comment
    View change log
    Run NER
    Run Name scripts, other?
    Should add record title and number to top of page
    add status after title, with toggle for approve/publish
:)
declare function app:rec-dashboard($node as node(), $model as map(*)){
(
<div class="col-md-2 top-padding">
<h3>Record Status </h3>
<!-- Should add option here for changing status? -->
<span class="alert alert-{if(app:rec-status($node,$model) = 'published') then 'success' else 'danger'}">{app:rec-status($node,$model)}</span>
<ul class="nav nav-pills nav-stacked top-padding">
  <li class="active"><a href="#tab_rec" data-toggle="pill"> <i class="glyphicon glyphicon-file"></i> Review Record</a></li>
  <li><a href="#tab_tei" data-toggle="pill"> <i class="glyphicon glyphicon-file"></i> View TEI</a></li>
  <li><a href="#tab_change" data-toggle="pill"><i class="glyphicon glyphicon-stats"></i> Review Changes</a></li>
  <li><a href="#tab_comments" data-toggle="pill"><i class="glyphicon glyphicon-comment"></i> Comments </a></li>
  <li><a href="#tab_actions" data-toggle="pill"><i class="glyphicon glyphicon-edit"></i> Actions</a>
  <li><a href="#tab_ner" data-toggle="pill" class="indent ner" data-url="{$global:app-root}/modules/services/ner.xql?id={$app:id}" data-param-run="no"> NER </a></li>
  <li><span class="indent"> Name normalization</span></li>
       <!-- <ul>
            <li>
            <a href="tab_ner" data-toggle="pill" data-url="/exist/apps/srophe-forms/services/run-test.xql?id={$app:id}" id="ner">Run NER</a></li>
            <li>Run name normalization</li>
        </ul>
        -->
  </li>
  <!--
  <li><span class="indent"><a href="modules/services/sosol-submit.xql?id={$app:id}"> Submit to Perseids 1</a></span></li>
  <li><span class="indent"><a href="modules/services/sosol.xql?id={$app:id}"> Submit to Perseids 2</a></span></li>
  -->
  <li><span class="indent"><a href="javascript:poptastic('modules/services/sosol-submit.xql?id={$app:id}')"> Submit to Perseids </a></span></li>
  <li><span class="indent"> Publish [Forthcoming]</span></li>
  <li><span class="indent"><a href="modules/download.xql?id={$app:id}"> Download TEI</a></span></li>

</ul>
  <span>
  <br/>
    {
        let $id := tokenize($app:id,'/')[last()]
        let $next := xs:integer($id) + 1
        let $prev := xs:integer($id) - 1
        let $next-uri := replace($app:id,$id,string($next))
        let $prev-uri := replace($app:id,$id,string($prev))
        return
            (<a class="btn btn-default" href="?id={$prev-uri}"><span class="glyphicon glyphicon-backward" aria-hidden="true"/> Previous </a>,
            <a class="btn btn-default" href="?id={$next-uri}"> Next <span class="glyphicon glyphicon-forward" aria-hidden="true"/> </a>)
    }
  </span>
  </div>,
<div class="tab-content col-md-10  top-padding">
        <div class="tab-pane active" id="tab_rec">
            {app:review-rec($node,$model)}
        </div>
        <div class="tab-pane" id="tab_tei">
            {app:review-rec-tei($node,$model)}
        </div>
        <div class="tab-pane" id="tab_change">
                <h3><i class="glyphicon glyphicon-stats"></i> Change log</h3>
                {app:get-changes($node,$model)}
        </div>
        <div class="tab-pane" id="tab_comments">
                <h3><i class="glyphicon glyphicon-comment"></i> Comments</h3>
                <div id="fail" class="error alert" style="display:none;">You do not have persmission to edit this resource</div>
                {app:get-comments-form($node,$model)}
                <div style="display:block; padding:.5em; float:none;clear:both;">
                    <hr/>
                    <div id="new-comments"/>
                    <div id="all-comments">
                        {comments:print-comments($node,$model)}
                    </div>
                    <hr/>
                </div>
        </div>
        <div class="tab-pane" id="tab_ner">
            <h3><i class="glyphicon glyphicon-edit"></i>NER Results</h3>
            <div id="ner-results">
                <span class="label label-default loading">
                <i class='icon-spinner icon-spin icon-large'></i>
                <i class="icon-upload icon-large"></i> Loading Data</span>
            </div>
        </div>
 </div>)

};

(:
 : Grab dev view of selected record, uses iframe to load view, to eliminate need for code duplication.
 let $uri := if($app:id != '') then replace($app:id,'http://syriaca.org/','http://wwwb.library.vanderbilt.edu/') else ()
:)
declare function app:review-rec($node as node(), $model as map(*)){
    <div>
        <iframe id="rec-review-frame" src="{global:internal-links($app:id)}" frameborder="0" border="0" cellspacing="0" style="border-style: none;width: 100%; height: 620px;"></iframe>
    </div>
};

(:
 : Grab dev view of selected record, uses iframe to load view, to eliminate need for code duplication.
:)
declare function app:review-rec-tei($node as node(), $model as map(*)){
    <div>
     <textarea style="width: 95%; height: 550px;">
         {$model("data")}
     </textarea>
    <!--
        <iframe id="rec-review-frame" src="{global:internal-links($app:id)}/tei" frameborder="0" border="0" cellspacing="0" style="border-style: none;width: 100%; height: 620px;"></iframe>
     -->
    </div>
};

(:~
 : Comments form used by review-recs.html
:)
declare %templates:wrap function app:get-comments-form($node as node(), $model as map(*)){
<form id="comments" method="post" action="modules/submit-comments.xql">
    <!--<h3>Add Comments</h3>-->
    <div class="section">
    <label>Name </label>
    <input name="editor" type="text" style="margin-left:.5em;"/><br/>
    <label>Email </label>
    <input name="email" type="text" style="margin-left:.5em;"/><br/>
    <label>Status </label>
    <select name="status" class="form-control"  style="margin-left:.5em; width:30%;">
        <option value="pending">Pending</option>
        <option value="approved">Approved</option>
    </select><br/>
    <textarea rows="6" class="col-md-8" name="comment"/><br/>
    <input name="id" type="hidden" value="{$app:id}"/>
    <input name="name" type="hidden" value="{request:get-attribute("org.exist.demo.login.user")}"/>
    <!-- start reCaptcha API
    <script type="text/javascript" src="http://api.recaptcha.net/challenge?k=6Lf1uvESAAAAAPiMWhCCFcyDqj8LVNoBKwkROCia"/>
    <noscript>
        <iframe src="http://api.recaptcha.net/noscript?k=6Lf1uvESAAAAAPiMWhCCFcyDqj8LVNoBKwkROCia" height="100" width="100" frameborder="0"/>
        <br/>
        <textarea name="recaptcha_challenge_field" rows="3" cols="40"/>
        <input type="hidden" name="recaptcha_response_field" value="manual_challenge"/>
    </noscript>
    -->
    <div class="row">
        <div class="col-md-12">
            <input class="btn btn-primary" type="submit" value="Submit"/>
        </div>
    </div>
    </div>
</form>
};


(:~
 : All TEI record changes used by review-rec.html
:)
declare %templates:wrap function app:get-changes($node as node(), $model as map(*)){
let $rec := $model("data")
return
<div>
    <ul>
    {
        for $change in $rec/descendant::tei:change
        return
            <li>{string($change/@when)}: {$change/text()}</li>
    }
    </ul>
</div>
};

(:~
 : Dashboard function outputs collection statistics for individual.
 : ex:
 :      <div data-template="app:index-dashboard" data-template-collection-title="The Syriac Biographical Dictionary" data-template-collection-icon="user" data-template-style="primary"/>
 : $collection-title title of sub-module/collection
 : $collection-icon bootstrap icon to use for display, default is 'file'
 : $style bootstrap style for panels, default is 'primary'
:)
declare function app:index-dashboard($node as node(), $model as map(*), $collection-title as xs:string?, $collection-icon as xs:string?, $style as xs:string?){
    let $coll-path := concat("collection('",$global:data-root,"')//tei:title[. = '",$collection-title,"']")
    let $count := count(util:eval($coll-path))
    let $icon-style := if($collection-icon !='') then $collection-icon else 'file'
    let $panel-style := if($style !='') then $style else 'primary'
    return
        <div class="panel panel-{$panel-style}">
            <div class="panel-heading">
                <div class="row">
                    <div class="col-xs-3"><i class="glyphicon glyphicon-{$icon-style}"></i></div>
                        <div class="col-xs-9 text-right">
                            <div class="huge">{$count}</div><div> {$collection-title} </div>
                        </div>
                    </div>
                </div>
                <a role="button" href="browse.html?collection-title={$collection-title}">
                    <div class="panel-footer">
                        <span class="pull-left">See Records</span>
                        <span class="pull-right"><i class="glyphicon glyphicon-circle-arrow-right"></i></span>
                        <div class="clearfix"></div>
                    </div>
                </a>
            </div>
};

(:~
 : Forms dashboard
:)
declare function app:forms-dashboard($node as node(), $model as map(*)){
<form action="{$global:app-root}/forms/services/increment-uri.xql" role="increment-uris" method="post">
{
    let $ids := doc($global:app-root || '/forms/services/syr-ids.xml')
    for $r in $ids//*:div
    let $class := string($r/@class)
    let $next := $r/descendant::*:last-calculated/@num + 1
    let $nextURI := concat(substring-before($r/descendant::*:last-calculated/@uri, $r/descendant::*:last-calculated/@num),$next) 
    return 
        <div>
            <h3>{$class}</h3>
            <div class="indent">
                <p> Next Available URI:  
                <code>{string($nextURI)}</code></p>
                <p>
                <button class="btn btn-default" name="num" type="submit" value="{$next}"><span class="glyphicon glyphicon-save-file"/> Reserve URI</button>
                &#160;<button class="btn btn-default" name="new-rec" type="submit" value="{$next}"><span class="glyphicon glyphicon-pencil"/> Reserve URI and Create TEI</button>
                &#160;<a class="togglelink btn btn-default" data-toggle="collapse" data-target="#showRangeForm{$class}"><span class="glyphicon glyphicon-save-file"/> Reserve URI range</a>
                &#160;<a class="togglelink btn btn-default" data-toggle="collapse" data-target="#moreDetails{$class}"><span class="glyphicon glyphicon-question-sign"/> More Info</a></p>
                <div class="collapse" id="showRangeForm{$class}" style=" margin:1em;border:1px solid #eeee;">
                    <div class="form-group">
                        <label for="idrange">URI Range: </label>
                        <div class="form-inline">
                            <input type="text" id="start" name="start" placeholder="Start Range (numeric values only)" class="form-control"/>&#160;
                            to &#160;<input type="text" id="end" name="end" placeholder="End Range (numeric values only)" class="form-control"/>
                            <br/>
                            <textarea rows="4" cols="50" id="notes" name="notes" placeholder="Notes about this URI range"/>
                        </div>
                    </div>
                </div>
                <div class="collapse" id="moreDetails{$class}" style="padding:1em; margin:1em;border:1px solid #eeee;">
                    <p>Last URI in the development database : {string($r/descendant::*:last-dev/@num)}</p>
                    {
                        for $reserved in $r/descendant::*:reserved/*:range
                        return 
                        <p>
                            <b>Reserved range: </b> {string($reserved/@start)} to {string($reserved/@end)}<br/>
                            Notes {string($reserved/@note)} &#160;<i> -{string($reserved/@who)}</i><br/>
                        </p>
                    }
                </div>
            </div>
        </div>
}
</form>
};
