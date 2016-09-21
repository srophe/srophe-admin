xquery version "3.0";

(:~
 : Build email from form returns error or sucess message to ajax function
 :)

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace mail="http://exist-db.org/xquery/mail";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace recap = "http://www.exist-db.org/xquery/util/recapture" at "recaptcha.xqm";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";
declare variable $id {request:get-parameter('id','')};

declare function local:build-message(){
  <mail>
    <from>Syriaca.org Administrative Module &lt;david.a.michelson@vanderbilt.edu&gt;</from>
    <to>wsalesky@gmail.com</to>
    <subject>New place data added for review</subject>
    <message>
      <xhtml>
           <html>
               <head>
                 <title>New place data added for review</title>
               </head>
               <body>
                 <p>Name: {request:get-parameter('name','')}</p>
                 <p>e-mail: {request:get-parameter('email','')}</p>
                 <p>Subject: {request:get-parameter('subject','')} {$place}</p>
                 <p>{$place-uri}</p>
                 {request:get-parameter('comments','')}
              </body>
           </html>
      </xhtml>
    </message>
  </mail>
};

let $cache := 'change this value to force page refresh 33'
return
    if(exists(request:get-parameter('email','')) and request:get-parameter('email','') != '')
        then
            if(exists(request:get-parameter('comments','')) and request:get-parameter('comments','') != '')
              then
               if(local:recaptcha() = true()) then
                 if (mail:send-email(local:build-message(),"library.vanderbilt.edu", ()) ) then
                   <h4>Thank you. Your message has been sent.</h4>
                 else
                   <h4>Could not send message.</h4>
                else 'Recaptcha fail'
            else  <h4>Incomplete form.</h4>
   else  <h4>Incomplete form.</h4>