create or replace function shredResource() returns void
as $$
declare
x integer = 1;

begin

with resourcexml as 
(
select 
unnest(
	xpath(
	'/root/resource'
	,data
	) 
) as data
from gemexport
) 
,
/*****************************shredding og inserts til resource tabel  ************************************/
resourceshredded as
(
select 
	xpath(
	'ID/text() 
	| title/text() 
	| description/text() 
	| itemdate/recordcreated/text() 
	| itemdate/placedonline/text() 
	| identifier/url/text()
	| publisher/name/text()
	| publisher/agency/text()'
	,data
	) as shred

from resourcexml
)


insert into resource
	select xmlserialize(content shred[1] as text)::integer
	,shred[2]
	,shred[3]
	,xmlserialize(content shred[4] as text)::date
	,xmlserialize(content shred[5] as text)::date
	,shred[6]
	,shred[7]
	,shred[8]
from resourceshredded

loop 



x = x +1;
exit when x > 10;
end loop;


/*
--tjek at area_id_in også er et geo_def area!!
select count(*)
from area
where area.area_id = area_id_in
and type = 'geo_area' into area_found;

if area_found > 0
then
 insert into grid(description)
 values(area_id_in::text)
 returning grid.grid_id into my_grid;

 insert into grid_area(grid_id,area_id)
 values(my_grid,area_id_in);
else
 raise exception 'angivet area er ikke af type geo_area';
end if;
*/
end;
$$
language plpgsql;


select shredResource();