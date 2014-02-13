declare function local:analyze_attributes($elements as item()*)
as element()*
{ 
     for $att in distinct-values($elements/@*/name())
     return <attribute name='{$att}' maxlength='{max($elements/@*[name() = $att]/string-length())}'/>
};




declare function local:analyze_maxlength($elements as item()*)
as xs:string
{ 
   if($elements/text()) then string(max($elements/text()/string-length())) else ''
};

declare function local:analyze_card($parents as item()*,$child_name as xs:string)
as xs:string
{ 
  let $child_count := $parents/count(*[name()=$child_name])
  let $min := min($child_count)
  let $max := max($child_count)
  let $result := if($min = 1 and $max = 1) then '1:1' else  (:required, only one :)
                 if($min = 0 and $max = 1) then '0:1' else  (:optional, only one :)
                 if($min = 0 and $max > 1) then concat('0:n','(',$max,')') else (:optional, more than one :)
                 if($min > 0 and $max > 1) then concat('1:n','(',$max,')') else 'ERROR'(:required, more than one :)
                 
  return $result
};

declare function local:analyze2($elements as item()*)
as element()*
{ 
   let $names :=  distinct-values($elements/*/name())
   for $el in $names 
   let  $maxlength := local:analyze_maxlength($elements/*[name()=$el])
   let $card := local:analyze_card($elements,$el)
   return 
   <element name='{$el}' maxlength='{$maxlength}' card='{$card}'>
       {local:analyze_attributes($elements/*[name()=$el])}
       {local:analyze2($elements/*[name()=$el])}
   </element>
};

declare function local:analyze($elements as item()*)
as element()
{ 
   <elements>{local:analyze2($elements)}</elements>
};

local:analyze(/)