xquery version "3.0";
(:~
 : Post processing of records finalized by Persieds
 : Adds new names for names containing left and right half ring symbols, they do not get ignored by eXistdb's diacritic insensitive search. 
 : Adds change statement
 : Other prepublication processing can happen here. 
 : Called by sosol.pp.xql 
:)

module namespace updates="http://syriaca.org/updates";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Look for left-half-ring add alternate names ʾ
 : Add alternate names replacing 'ʾ' with a space and '’'
:)
declare function updates:left-half-ring($rec){
    if($rec/descendant::tei:place/tei:placeName[contains(text(),'ʾ')]) then 
        let $parent := $rec/descendant::tei:body/tei:listPlace/tei:place
        return 
            for $names in $parent/tei:placeName[contains(.,'ʾ')]
            let $name := $names/text()
            let $id := $names/@xml:id
            let $new-name := 
                (
                    if($parent/tei:placeName/text() = replace($name,'ʾ','')) then ()
                    else
                        <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'a')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʾ','')}</placeName>,
                    if($parent/tei:placeName/text() = replace($name,'ʾ','’')) then ()  
                    else
                        <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'b')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʾ','’')}</placeName>
                )
            return
                if(not(empty($new-name))) then
                    update insert $new-name following $parent/tei:placeName[last()]
                else ()    
    else if($rec/descendant::tei:body/tei:listPerson/tei:person/tei:persName/descendant-or-self::*[contains(text(),'ʾ')]) then 
        let $parent := $rec//tei:body/tei:listPerson/tei:person   
        return 
            for $names in $parent/tei:persName[descendant-or-self::*[contains(text(),'ʾ')]]
            let $name := string-join($names/node(),' ')
            let $id := $names/@xml:id
            let $new-name := 
                (
                    if($parent/tei:persName[string-join(node(),' ')] = replace($name,'ʾ','')) then ()
                    else
                        <persName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'a')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʾ','')}</persName>,
                    if($parent/tei:persName[string-join(node(),' ')] = replace($name,'ʾ','’')) then ()  
                    else
                       <persName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'b')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʾ','’')}</persName>
                )
            return 
                if(not(empty($new-name))) then
                    update insert $new-name following $parent/tei:persName[last()]
                else ()
    else if($rec/descendant::tei:body/tei:bibl/tei:title/descendant-or-self::*[contains(text(),'ʾ')]) then
        let $parent := $rec//tei:body/tei:bibl   
        return 
            for $names in $parent/tei:title[descendant-or-self::*[contains(text(),'ʾ')]]
            let $name := string-join($names/node(),' ')
            let $id := $names/@xml:id
            let $new-name := 
                (
                    if($parent/tei:title[string-join(node(),' ')] = replace($name,'ʾ','')) then ()
                    else
                        <title xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'a')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʾ','')}</title>,
                    if($parent/tei:title[string-join(node(),' ')] = replace($name,'ʾ','’')) then ()  
                    else
                       <title xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'b')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʾ','’')}</title>
                )
            return 
                if(not(empty($new-name))) then
                    update insert $new-name following $parent/tei:title[last()]
                else ()
    else ()
};

(:~
 : Look for right-half-ring add alternate names ʿ
 : Add alternate names replacing 'ʿ' with a space and '‛'
:)
declare function updates:right-half-ring($rec){
    if($rec/descendant::tei:place/tei:placeName[contains(text(),'ʿ')]) then 
        let $parent := $rec/descendant::tei:body/tei:listPlace/tei:place
        return 
            for $names in $parent/tei:placeName[contains(.,'ʿ')]
            let $name := $names/text()
            let $id := $names/@xml:id
            let $new-name := 
                (
                    if($parent/tei:placeName/text() = replace($name,'ʿ','')) then ()
                    else
                        <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'c')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʿ','')}</placeName>,
                    if($parent/tei:placeName/text() = replace($name,'ʿ','‛')) then ()  
                    else
                        <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'d')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʿ','‛')}</placeName>
                )
            return
                if(not(empty($new-name))) then
                    update insert $new-name following $parent/tei:placeName[last()]
                else ()    
    else if($rec/descendant::tei:body/tei:listPerson/tei:person/tei:persName/descendant-or-self::*[contains(text(),'ʿ')]) then 
        let $parent := $rec//tei:body/tei:listPerson/tei:person   
        return 
            for $names in $parent/tei:persName[descendant-or-self::*[contains(text(),'ʿ')]]
            let $name := string-join($names/node(),' ')
            let $id := $names/@xml:id
            let $new-name := 
                (
                    if($parent/tei:persName[string-join(node(),' ')] = replace($name,'ʿ','')) then ()
                    else
                        <persName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'c')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʿ','')}</persName>,
                    if($parent/tei:persName[string-join(node(),' ')] = replace($name,'ʿ','‛')) then ()  
                    else
                       <persName xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'d')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʿ','‛')}</persName>
                )
            return 
                if(not(empty($new-name))) then
                    update insert $new-name following $parent/tei:persName[last()]
                else ()
    else if($rec/descendant::tei:body/tei:bibl/tei:title/descendant-or-self::*[contains(text(),'ʿ')]) then
        let $parent := $rec//tei:body/tei:bibl   
        return 
            for $names in $parent/tei:title[descendant-or-self::*[contains(text(),'ʿ')]]
            let $name := string-join($names/node(),' ')
            let $id := $names/@xml:id
            let $new-name := 
                (
                    if($parent/tei:title[string-join(node(),' ')] = replace($name,'ʿ','')) then ()
                    else
                        <title xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'c')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʿ','')}</title>,
                    if($parent/tei:title[string-join(node(),' ')] = replace($name,'ʿ','‛')) then ()  
                    else
                       <title xmlns="http://www.tei-c.org/ns/1.0" xml:id="{concat($id,'d')}" xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script">{replace($name,'ʿ','‛')}</title>
                )
            return 
                if(not(empty($new-name))) then
                    update insert $new-name following $parent/tei:title[last()]
                else ()
    else ()            
};

(:~
 : Add change statment
:)
declare function updates:do-change-stmt($rec){
    if($rec/descendant::tei:place/tei:placeName[contains(text(),('ʿ','ʾ'))] or 
        $rec/descendant::tei:body/tei:bibl/tei:title/descendant-or-self::*[contains(text(),('ʿ','ʾ'))] or
        $rec/descendant::tei:body/tei:listPerson/tei:person/tei:persName/descendant-or-self::*[contains(text(),('ʿ','ʾ'))]
        ) then  
        let $change := 
            <change xmlns="http://www.tei-c.org/ns/1.0" who="http://syriaca.org/documentation/editors.xml#srophe-admin-scripts" when="{current-date()}">Updated: Updated alternate names for search functionality, corrects bug in https://github.com/srophe/srophe-eXist-app/issues/874.</change>
        return
            (
             update insert $change preceding $rec/descendant::tei:teiHeader/tei:revisionDesc/tei:change[1],
             update value $rec/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date with current-date())
    else ()         
};

(:~
 : Delete any existing alternative names
 : xml:lang="en-x-srp1" syriaca-tags="#syriaca-simplified-script"
:)
declare function updates:clear-alternate-names($rec){
    for $names in $rec/descendant::*[@xml:lang='en-x-srp1'][@syriaca-tags='#syriaca-simplified-script']
    return 
            update delete $names
};

(:~
 : Run all updates on submitted record. 
:)
declare function updates:update-rec($rec){
    try {
            (
                (   updates:clear-alternate-names($rec),
                    updates:left-half-ring($rec), 
                    updates:right-half-ring($rec),
                    updates:do-change-stmt($rec)), 
                response:set-status-code( 200 ),
                <response status="okay">
                     <message>Updates done </message>
                 </response>)
         } catch * { 
            (response:set-status-code( 401 ),
                <response status="fail">
                    <message>Failed to update resource: {concat($err:code, ": ", $err:description)}</message>
                </response>)
         }          
};
