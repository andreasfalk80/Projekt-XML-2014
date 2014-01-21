/************************************ Hoved funktion: "main" **************************************************/
drop function if exists shredResources(xml);
create function shredResources(root xml) returns void
as $$
declare
idx integer;
resources xml[];
resourceXml xml;

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
  resourceXml = resources[idx];
  perform shredResource(resourceXml);
  idx = idx + 1;
exit when idx > array_length(resources,1);
end loop;

end
$$
language plpgsql;

/************************************ Shredder funktion: shredResource  **************************************************/
drop function if exists shredResource(xml);
create function shredResource(resourceXml xml) returns void 
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
select xpath('child::*',resourceXml) into resourceChildren;
--raise info 'resourceChildren: %', resourceChildren;

--første loop finder alle værdier der skal bruges til at oprette en forekomst i resource tabellen
idy = 1;
loop
select xpath('name()',resourceChildren[idy]) into tagname;
--raise info 'tagname: %' , tagname[1]::text;

case tagname[1]::text
when 'ID' then
	select xmlasText(xpath('ID',resourceXml))::integer into resourceId;
when 'title' then
	select xmlasText(xpath('title',resourceXml)) into title;
when 'description' then
	select xmlasText(xpath('description',resourceXml)) into description;
when 'itemdate' then
	select xmlasText(xpath('itemdate/recordcreated',resourceXml))::date into recordcreated;
	select xmlasText(xpath('itemdate/placedonline',resourceXml))::date into placedOnline;
when 'identifier' then
	select xmlasText(xpath('identifier/url',resourceXml)) into identifierUrl;
when 'publisher' then
	select xmlasText(xpath('publisher/name',resourceXml)) into publisherName;
	select xmlasText(xpath('publisher/agency',resourceXml)) into publisherAgency;
else
-- do nothing. resten af elementerne behandles i loop 2
end case;
idy = idy +1;
exit when idy > array_length(resourceChildren,1);
end loop;

--indsæt på tabel resource, så efterfølgende indsæt kan referere resourceId som foreignkey
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
	perform shredImage(resourceId,resourceChildren[idy]);
when 'interestingfact' then
	perform shredInterestingFact(resourceId,resourceChildren[idy]);
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

/************************************ Shredder funktion: shredImage  **************************************************/
drop function if exists shredImage(integer,xml);
create function shredImage(resourceId integer, image xml) returns void
as $$
declare
idy integer;
imageChildren xml[];
tagname xml[];
-- variable til værdier der skal gemmes på tabellen image
url text;
caption text;
sourceUrl text;
altText text;

begin
--xpath med tjek for om der er data i child elementerne
select xpath('/image[not(url ="" and caption ="" and alttext="" and sourceurl="")]/child::*',image) into imageChildren;

/*vi indsætter kun hvis vi finder data i et af tags.. 
hvis xpath returnere ingenting, har jeg svært ved at tjekke det, da hverken tjek for null eller længde på array = 0 virker
*/
if imageChildren[1] is not null
then 
idy = 1;
loop
select xpath('name()',imageChildren[idy]) into tagname;
case tagname[1]::text
when 'url' then
	select xmlasText(xpath('url',image)) into url;
when 'caption' then
	select xmlasText(xpath('caption',image)) into caption;
when 'sourceurl' then
	select xmlasText(xpath('sourceurl',image)) into sourceUrl;
when 'alttext' then
	select xmlasText(xpath('alttext',image)) into altText;
else
-- do nothing
end case;
idy = idy +1;
exit when idy > array_length(imageChildren,1);
end loop;

--indsæt på tabel image, 
insert into image (resourceid,url,caption,sourceurl,alttext)
values	(resourceId
	,url
	,caption
	,sourceUrl
	,altText);
end if;
end
$$
language plpgsql;


/************************************ Shredder funktion: shredInterestingFact  **************************************************/
drop function if exists shredInterestingFact(integer,xml);
create function shredInterestingFact(resourceId integer, fact xml) returns void
as $$
declare
idy integer;
factChildren xml[];
tagname xml[];
-- variable til værdier der skal gemmes på tabellen fact
url text;
text text;
sourceUrl text;
altText text;

begin
--xpath med tjek for om der er data i child elementerne
select xpath('/interestingfact[not(url ="" and text ="")]/child::*',fact) into factChildren;

/*vi indsætter kun hvis vi finder data i et af tags.. 
hvis xpath returnere ingenting, har jeg svært ved at tjekke det, da hverken tjek for null eller længde på array = 0 virker
*/
if factChildren[1] is not null
then 
idy = 1;
loop
select xpath('name()',factChildren[idy]) into tagname;
case tagname[1]::text
when 'url' then
	select xmlasText(xpath('url',fact)) into url;
when 'text' then
	select xmlasText(xpath('text',fact)) into text;
else
-- do nothing
end case;
idy = idy +1;
exit when idy > array_length(factChildren,1);
end loop;

--indsæt på tabel fact, 
insert into interestingFact(resourceid,url,text)
values	(resourceId
	,url
	,text);
end if;
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




select shredResources(data)
from gemexport
;