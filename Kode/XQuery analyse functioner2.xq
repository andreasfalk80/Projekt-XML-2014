declare function local:test($elements as item()*)
as element()*
{ 
   let $names :=  distinct-values($elements/*/name())
   for $el in $names 
   return <element name='{$el}'>{local:test($elements/*[name()=$el])}</element>
     
};

<elements>{local:test(/)}</elements>