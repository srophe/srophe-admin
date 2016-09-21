xquery version "3.0";

import module namespace comments="http://syriaca.org/srophe-admin/comments" at "comments.xql";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

declare variable $id {request:get-parameter('id','')};
declare variable $comment {request:get-parameter('comment','')};
declare variable $editor {request:get-parameter('editor','')};
declare variable $email {request:get-parameter('email','')};
declare variable $delete {request:get-parameter('delete','')};
declare variable $comment-id {request:get-parameter('comment-id','')};
declare variable $status {request:get-parameter('status','')};

declare variable $rec-id {if($id) then tokenize(replace($id,'/tei',''),'/')[last()] else ()};
declare variable $file-path {if($id) then replace(replace(replace($comments:id,'http://syriaca.org/','/db/apps/srophe-comments/data/comments/'),'/tei',''), $rec-id,'') else ()};

declare function local:create-feed(){
<feed xmlns="http://www.w3.org/2005/Atom">
	<title>Administrative comments for {$id}</title>
    <updated>{current-date()}</updated>
	<subtitle>Processing comments for {$id}</subtitle>
	   <author>
		<name>Syriaca.org</name>
		<uri>syrica.org</uri>
	   </author>
	<id>{concat('comments:',$id)}</id>
    {local:create-entry()}
</feed>
};

declare function local:create-entry(){
let $user := xmldb:get-current-user()
let $name := if ($editor) then $editor else sm:get-account-metadata($user, xs:anyURI('http://axschema.org/namePerson'))
return
<entry xmlns="http://www.w3.org/2005/Atom">
    <title>Comment for {$id}</title>
    <id>tag:{util:uuid()}:{$id}</id>
    <updated>{current-date()}</updated>
    <published>{current-date()}</published>
    <author>
        <name>{if($editor) then $editor else ()}</name>
        <email>{if($email) then $email else ()}</email>
    </author>
    <summary>{$status} : {substring($comment,1,25)}</summary>
    <content type="xhtml">
        <div xmlns="http://www.w3.org/1999/xhtml">
            <p>{string($comment)}</p>
        </div>
    </content>
</entry>
};

declare function local:add-entry($feed){
    if(doc-available($feed)) then
        let $doc := doc($feed)
        return
            update insert local:create-entry() preceding $doc//atom:entry[1]
    else (: if collection available then create, else create collection, then comment. :)
        try {
            xmldb:store($file-path, concat($rec-id, '.xml') , local:create-feed())
        } catch * {
            <error>Error {$err:code}: {$err:description}</error>
        }

};

declare function local:delete-comment($feed){
    if($comment-id != '') then
        let $doc := doc($feed)
        let $comment := $doc//atom:entry[atom:id = $comment-id]
        return
            if($comment/following-sibling::* or $comment/preceding-sibling::*) then
                update delete $comment
            else
                try {
                    xmldb:remove($file-path, concat($rec-id,'.xml'))
                } catch * {
                    <error>Error {$err:code}: {$err:description}</error>
                }

    else ()
};

<div id="response">
    {
    let $feed := concat($file-path, $rec-id, '.xml')
    return
        if($comment) then
            (local:add-entry($feed), comments:print-comment(local:create-entry()))
        else if($comment-id) then
            (local:delete-comment($feed),comments:get-comments())
        else <p>No form data!</p>
    }
</div>