drop function if exists searchDescription(text);
create function searchDescription(word text) returns TABLE(resourceid int,title text, description text)
as $$
declare
begin
return query 
select r.resourceid,r.title,r.description
FROM resource as r
WHERE fts_index_col @@ to_tsquery('english', word);
end
$$
language plpgsql;



--test search of 'science'
select *
from searchDescription('science');