declare function local:test($element as element()+)
as element()*
{ 
   for $child in $element/* 
   return <element name='{$child/name()}'>{local:test($child)}</element>
};

<elements>{local:test(/root)}</elements>