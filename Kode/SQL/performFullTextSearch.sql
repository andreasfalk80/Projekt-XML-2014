drop function if exists searchDescription(text);
create function searchDescription(word text) returns setof xml
as $$
declare
begin
return query select 
xmlelement(name result,
  xmlagg(xmlelement(name partialresource,xmlforest(r.resourceid,r.title,r.description))))
FROM resource as r
WHERE fts_index_col @@ to_tsquery('english', word);
end
$$
language plpgsql;



--test search of 'science'
select *
from searchDescription('brains');