/************************************ Hoved funktion: "main" **************************************************/
drop function if exists shredResources(xml);
create function shredResources(root xml) returns void
as $$
declare
idx integer;
resources xml[];
resourceXml xml;
sum integer;
taeller integer;
begin
raise info 'Sletter alt fra tabellerne: resource, image, interestingfact, keyword, subject';
--slet indhold i tabellerne
delete from resource;
delete from image;
delete from interestingfact;
delete from keyword;
delete from subject;


raise info 'Indlæser data fra xml';
select 
	xpath(
	'/root/resource'
	,root
	) as data
into resources;

idx = 1;
loop
  --vælg det aktuelle <resource>...</resource> element
  resourceXml = resources[idx];
  perform shredResource(resourceXml);
  idx = idx + 1;
exit when idx > array_length(resources,1);
end loop;
sum = 0;
select count(*) from resource into taeller;
sum = sum + taeller;
raise info 'Indsat % records i tabel: resource' , taeller;
select count(*) from image into taeller;
sum = sum + taeller;
raise info 'Indsat % records i tabel: image' , taeller;
select count(*) from interestingfact into taeller;
sum = sum + taeller;
raise info 'Indsat % records i tabel: interestingfact' , taeller;
select count(*) from keyword into taeller;
sum = sum + taeller;
raise info 'Indsat % records i tabel: keyword' , taeller;
select count(*) from subject into taeller;
sum = sum + taeller;
raise info 'Indsat % records i tabel: subject' , taeller;

raise info 'Indsat i alt % records' , sum;
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

--første loop finder alle værdier der skal bruges til at oprette en forekomst i resource tabellen
idy = 1;
loop
select xpath('name()',resourceChildren[idy]) into tagname;

case tagname[1]::text
when 'ID' then
	select xmlasText(xpath('/ID',resourceChildren[idy]))::integer into resourceId;
when 'title' then
	select xmlasText(xpath('/title',resourceChildren[idy])) into title;
when 'description' then
	select xmlasText(xpath('/description',resourceChildren[idy])) into description;
when 'itemdate' then
	select xmlasText(xpath('/itemdate/recordcreated',resourceChildren[idy]))::date into recordcreated;
	select xmlasText(xpath('/itemdate/placedonline',resourceChildren[idy]))::date into placedOnline;
when 'identifier' then
	select xmlasText(xpath('/identifier/url',resourceChildren[idy])) into identifierUrl;
when 'publisher' then
	select xmlasText(xpath('/publisher/name',resourceChildren[idy])) into publisherName;
	select xmlasText(xpath('/publisher/agency',resourceChildren[idy])) into publisherAgency;
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

case tagname[1]::text
when 'image' then
	perform shredImage(resourceId,resourceChildren[idy]);
when 'interestingfact' then
	perform shredInterestingFact(resourceId,resourceChildren[idy]);
when 'resourcekeywords' then
	perform shredResourceKeywords(resourceId,resourceChildren[idy]);
when 'subjects' then
	perform shredSubject(resourceId,resourceChildren[idy]);
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
	select xmlasText(xpath('/url',imageChildren[idy])) into url;
when 'caption' then
	select xmlasText(xpath('/caption',imageChildren[idy])) into caption;
when 'sourceurl' then
	select xmlasText(xpath('/sourceurl',imageChildren[idy])) into sourceUrl;
when 'alttext' then
	select xmlasText(xpath('/alttext',imageChildren[idy])) into altText;
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
-- variable til værdier der skal gemmes på tabellen interestingfact
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
	select xmlasText(xpath('/url',factChildren[idy])) into url;
when 'text' then
	select xmlasText(xpath('/text',factChildren[idy])) into text;
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


/************************************ Shredder funktion: shredResourceKeywords  **************************************************/
drop function if exists shredResourceKeywords(integer,xml);
create function shredResourceKeywords(resourceId integer, resourceKeywords xml) returns void
as $$
declare
idy integer;
resourceKeywordsChildren xml[];
tagname xml[];
-- variable til værdier der skal gemmes på tabellen keywords
term text;

begin


--xpath finder child elementerne (altså en eller flere <term>..</term> elementer
select xpath('/resourcekeywords/keywords/child::*',resourceKeywords) into resourceKeywordsChildren;

idy = 1;
loop
select xpath('name()',resourceKeywordsChildren[idy]) into tagname;
case tagname[1]::text
when 'term' then
	select xmlasText(xpath('/term',resourceKeywordsChildren[idy])) into term;
else
-- do nothing
end case;

--indsæt på tabel keyword, 
insert into keyword(resourceid,term)
values	(resourceId
	,term);

idy = idy +1;
exit when idy > array_length(resourceKeywordsChildren,1);
end loop;

end
$$
language plpgsql;

/************************************ Shredder funktion: shredSubject  **************************************************/
drop function if exists shredSubject(integer, xml);
create function shredSubject(resourceId integer, subjectXml xml) returns void 
as $$
declare
idy integer;
idx integer;
subjectsChildren xml[];
subjectChildren xml[];
tagname xml[];
tagname2 xml[];
-- variable til værdier der skal gemmes på tabellen subject
category text;
subCategory text;
primarySubject text;

begin
--xpath finder child elementerne
select xpath('/subjects/child::*',subjectXml) into subjectsChildren;
--raise info 'subjectsChildren: %' , subjectsChildren;
--første loop finder alle subject elementerne
idx = 1;
loop
	select xpath('name()',subjectsChildren[idx]) into tagname;
--	raise info 'tag %' , tagname;
	case tagname[1]::text
	when 'subject' then
	select xpath('/subject/child::*',subjectsChildren[idx]) into subjectChildren;
	--andet loop finder alle blad elementerne
  	idy = 1;  
	loop
		select xpath('name()',subjectChildren[idy]) into tagname2;

		case tagname2[1]::text
		when 'category' then
			select xmlasText(xpath('/category',subjectChildren[idy])) into category;
		when 'subcategory' then
			select xmlasText(xpath('/subcategory',subjectChildren[idy])) into subCategory;
		when 'primary' then
			select xmlasText(xpath('/primary',subjectChildren[idy])) into primarySubject;
		else
		-- do nothing.
		end case;
		idy = idy +1;
	exit when idy > array_length(subjectChildren,1);
	end loop;	
	else
	-- do nothing.
	end case;

--indsæt på tabel subject
insert into subject (resourceid,category,subcategory,primarysubject)
values	(resourceId
	,category
	,subCategory
	,primarySubject);

idx = idx +1;
exit when idx > array_length(subjectsChildren,1);
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




select shredResources(data)
from gemexport
;