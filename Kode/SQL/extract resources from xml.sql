delete from resource;

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
,
insert_resource as
(
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
)
,
/*****************************shredding og inserts til interestingFact tabel  ************************************/
interestingFactshredded as
(
select
	xpath(
	' ID/text()
	| interestingfact/url/text() 
	| interestingfact/text/text()'
	, data
	) as shred
from resourcexml
where xpath_exists('//resource/interestingfact[not(url = "" and text = "")]',data)
)
,
insert_interestingFact as
(
insert into interestingFact (resourceId,url,text)
	select xmlserialize(content shred[1] as text)::integer
	,shred[2]
	,shred[3]
from interestingFactshredded
)
,
/*****************************shredding og inserts til keyword tabel  ************************************/
keywordshredded as
(
select
	xpath(
	' ID/text()
	| resourcekeywords/keywords/term/text()'
	, data
	) as shred
from resourcexml
where xpath_exists('//resource/resourcekeywords',data)


)
select * from keywordshredded








