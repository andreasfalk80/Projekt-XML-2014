declare function local:analyze_maxlength($elements as item()*)
as xs:string
{ 
   if($elements/text()) then string(max($elements/text()/string-length())) else ''
};

declare function local:analyze($elements as item()*)
as element()*
{ 
   let $names :=  distinct-values($elements/*/name())
   for $el in $names 
   return <element name='{$el}' 
   maxlength='{local:analyze_maxlength($elements/*[name()=$el])}'>
   {local:analyze($elements/*[name()=$el])}
   </element>
     
};

<elements>{local:analyze(/)}</elements>