/************************************ Hoved funktion: "main" **************************************************/
drop function if exists shredResources(xml);
create function shredResources(root xml) returns void
as $$
declare
idx integer;
resources xml[];
resource xml;

begin
--slet indhold i tabellerne
delete from resource;
delete from image;
delete from interestingfact;
delete from keyword;
delete from subject;

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
  --vælg det aktuelle <resource>...</resource> element
  resource = resources[idx];
  perform shredResource(resource);
  idx = idx + 1;
exit when idx > array_length(resources,1);
end loop;

end
$$
language plpgsql;

/************************************ Shredder funktion: shredResource  **************************************************/
drop function if exists shredResource(xml);
create function shredResource(resource xml) returns void 
as $$
declare
idy integer;
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
select xpath('child::*',resource) into resourceChildren;
--raise info 'resourceChildren: %', resourceChildren;

--første loop finder alle værdier der skal bruges til at oprette en forekomst i resource tabellen
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
else
-- do nothing. resten af elementerne behandles i loop 2
end case;
idy = idy +1;
exit when idy > array_length(resourceChildren,1);
end loop;

--indsæt på tabel resource
insert into resource (resourceid,title,description,recordcreated,placedonline,identifierurl,publishername,publisheragency)
values	(resourceId
	,title
	,description
	,recordCreated
	,placedOnline
	,identifierUrl
	,publisherName
	,publisherAgency);



--andet loop finder alle elementer der skal oprettes i selvstændige tabeller
idy = 1;
loop
select xpath('name()',resourceChildren[idy]) into tagname;
--raise info 'tagname: %' , tagname[1]::text;

case tagname[1]::text
when 'image' then
	--perform shredImage(resourceId,xpath('image',resource));
when 'interestingfact' then
--	raise info 'vi fandt interestingfact';
when 'resourcekeywords' then
--	raise info 'vi fandt resourcekeywords';
when 'subjects' then
--	raise info 'vi fandt subjects';
else
-- do nothing. resten af elementerne behandles i loop 1
end case;
idy = idy +1;
exit when idy > array_length(resourceChildren,1);
end loop;



end
$$
language plpgsql;




/************************************ hjælper funktion: xmlasText  **************************************************/
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


/************************************ Shredder funktion: shredImage  **************************************************/
drop function if exists shredImage(integer,xml);
create function shredImage(resourceId integer, image xml) returns void
as $$
declare
idy integer;
imageChildren xml[];
tagname xml[];
-- variable til værdier der skal gemmes på tabellen image
resourceId integer;
url text;
caption text;
sourceUrl text;
altText text;

begin
select xpath('child::*',image) into imageChildren;
raise info 'imageChildren: %', imageChildren;

idy = 1;
loop
select xpath('name()',imageChildren[idy]) into tagname;
--raise info 'tagname: %' , tagname[1]::text;

case tagname[1]::text
when 'url' then
	select xmlasText(xpath('url',image)) into url;
when 'caption' then
	select xmlasText(xpath('caption',image)) into caption;
when 'sourceurl' then
	select xmlasText(xpath('sourceurl',image)) into sourceUrl;
when 'alttext' then
	select xmlasText(xpath('alttext',image)) into altText;
end case;

idy = idy +1;
exit when idy > array_length(imageChildren,1);
end loop;


end
$$
language plpgsql;


select shredResources(data)
from gemexport
;