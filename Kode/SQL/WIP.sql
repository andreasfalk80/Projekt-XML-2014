drop function shredResources(xml);
create function shredResources(root xml) returns void
as $$
declare
idx integer;
idy integer;
resources xml[];
resource xml;
resourceChildren xml[];
tagname xml[];
-- variable til værdier der skal gemmes på tabellen resource
resourceId integer;
title text;
description text;
recordCreated date;
placedOnline date;
identifierUrl text;
publisherName text;
publisherAgency text;

begin

select 
	xpath(
	'/root/resource'
	,root
	) as data
into resources;
--raise info 'antal resources: %' , array_length(resources,1);


idx = 1;
loop
--raise info 'behandler idx: %' , idx;
--raise info 'indhold: %' , resource;


resource = resources[idx];

select xpath('child::*',resource) into resourceChildren;
--raise info 'resourceChildren.length: %' , array_length(resourceChildren,1);

idy = 1;
loop
select xpath('name()',resourceChildren[idy]) into tagname;
--raise info 'tagname: %' , tagname[1]::text;

case tagname[1]::text
when 'ID' then
	select xmlasText(xpath('ID',resource))::integer into resourceID;
when 'title' then
	select xmlasText(xpath('title',resource)) into title;
when 'description' then
	select xmlasText(xpath('description',resource)) into description;
when 'itemdate' then
	select xmlasText(xpath('itemdate/recordcreated',resource))::date into recordcreated;
	select xmlasText(xpath('itemdate/placedonline',resource))::date into placedOnline;
when 'identifier' then
	select xmlasText(xpath('identifier/url',resource)) into identifierUrl;
when 'publisher' then
	select xmlasText(xpath('publisher/name',resource)) into publisherName;
	select xmlasText(xpath('publisher/agency',resource)) into publisherAgency;
when 'image' then
--	raise info 'vi fandt image';
when 'interestingfact' then
--	raise info 'vi fandt interestingfact';
when 'resourcekeywords' then
--	raise info 'vi fandt resourcekeywords';
when 'subjects' then
--	raise info 'vi fandt subjects';
end case;

idy = idy +1;
exit when idy > array_length(resourceChildren,1);
end loop;



idx = idx + 1;
exit when idx > array_length(resources,1);
end loop;

end
$$
language plpgsql;


/*denne funktion virker på xml elementer af typen xml array med lignende indhold {<temp>dette er en tekst</temp>} */
drop function if exists xmlasText(xml[]);
create function xmlasText(fragment xml[]) returns text
as $$
declare
tmp xml[];

begin
select xpath('text()',fragment[1]) into tmp;
return xmlserialize(content tmp[1] as text);
end
$$
language plpgsql;




select shredResources(data)
from gemexport
;