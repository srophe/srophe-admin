xquery version "3.0";

module namespace comments="http://syriaca.org/srophe-admin/comments";

import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

declare variable $comments:id {request:get-parameter('id','')};
declare variable $comments:rec-id {if($comments:id) then tokenize(replace($comments:id,'/tei',''),'/')[last()] else ()};
declare variable $comments:file-path {if($comments:id) then replace(replace(replace($comments:id,'http://syriaca.org/',$global:comments-root,'/tei',''), $comments:rec-id,'') else ()};

(:~
 : Publish comments to place page.
 : If user is logged in allow access to delete function
:)
declare function comments:get-comments(){
let $feed := concat($comments:file-path, $comments:rec-id, '.xml')
return
    if(doc-available($feed)) then
        for $comments in doc($feed)//atom:entry
        return
           comments:print-comment($comments)
    else <p>No comments yet.</p>
};

declare function comments:print-comment($comments){
let $content := $comments/atom:content/child::*
let $comment-id := $comments/atom:id
let $name := $comments/atom:author/atom:name/text()
let $email := $comments/atom:author/atom:email/text()
let $date := $comments/atom:published/text()
return
    <div class="comments well">
        <header>Comment on {comments:format-dates($date)}</header>
        <div>{$content}</div>
        <div style="padding-left: 1em; margin-top:.5em; margin-left:1em; border-left:1px solid #ccc; color:#666;">
            <div>{$name}<br/>{$email}<br/></div>
        </div>
        {
         if(request:get-attribute("org.exist.demo.login.user")) then
            <span><a class="delete btn btn-primary btn-sm" href="modules/submit-comments.xql?delete=yes&amp;id={$comments:id}&amp;comment-id={$comment-id}">Delete </a></span>
         else ()
        }
    </div>
};
declare function comments:format-dates($date as xs:string?) as xs:string?{
    let $month :=
            if(tokenize($date,'-')[2] = '01') then 'January'
            else if(tokenize($date,'-')[2] = '02') then 'February'
            else if(tokenize($date,'-')[2] = '03') then 'March'
            else if(tokenize($date,'-')[2] = '04') then 'April'
            else if(tokenize($date,'-')[2] = '05') then 'May'
            else if(tokenize($date,'-')[2] = '06') then 'June'
            else if(tokenize($date,'-')[2] = '07') then 'July'
            else if(tokenize($date,'-')[2] = '08') then 'August'
            else if(tokenize($date,'-')[2] = '09') then 'September'
            else if(tokenize($date,'-')[2] = '10') then 'October'
            else if(tokenize($date,'-')[2] = '11') then 'November'
            else if(tokenize($date,'-')[2] = '12') then 'December'
            else ''
    let $day :=
            if(starts-with(tokenize($date,'-')[3],'0')) then substring-after(tokenize($date,'-')[3],'0')
            else tokenize($date,'-')[3]
    let $year := tokenize($date,'-')[1]
    return concat($month,' ',$day,', ',$year)

};

declare %templates:wrap function comments:print-comments($node as node(), $model as map(*)){
    comments:get-comments()
};
declare %templates:wrap function comments:publish-title($node as node(), $model as map(*)){
    let $feed := concat($comments:file-path, $comments:rec-id, '.xml')
    for $comments in doc($feed)/atom:feed
    return $comments/atom:title/text()
};