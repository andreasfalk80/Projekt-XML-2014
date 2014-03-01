drop function if exists reconstructResources();
create function reconstructResources() returns xml
as $$
declare

begin
return 
(select 
--xmlroot(

-- root
xmlelement(name root,
xmlattributes('http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi", 'resource.xsd' as "xsi:noNamespaceSchemaLocation"),
xmlagg(

-- resource
   xmlelement(name resource,

-- ID, title,description
      xmlforest(resourceid as "ID", Title, description),
-- itemdate
      xmlelement(name itemdate,
         xmlforest(recordcreated,placedonline)
      ),
-- identifier
      xmlelement(name identifier,
      xmlelement(name url,identifierurl)
      ),
-- publisher
      xmlelement(name publisher,
         xmlforest(publishername as name,publisheragency as agency)
      ),
-- image
      xmlelement(name image,
         xmlforest(imageurl as url,caption,alttext,sourceurl)
      ),
-- interestingfact
      xmlelement(name interestingfact,
         xmlforest(facturl as url,facttext as text)
      ),
-- resourcekeywords
      keywordxml      
      ,
-- subjects
      subjectxml      
      
   )
   )
)
--, version '1,0')

from 
(select 
res.resourceid,
res.title,
res.description,
res.recordcreated,
res.placedonline,
res.identifierurl,
coalesce(res.publishername,'') as publishername,
res.publisheragency,
coalesce(image.url,'') as imageurl,
coalesce(caption,'') as caption,
coalesce(alttext,'') as alttext,
coalesce(sourceurl,'') as sourceurl,
coalesce(fact.url,'') as facturl,
coalesce(fact.text,'') as facttext,
keyword.xml as keywordxml,
subject.xml as subjectxml


from resource as res
left join image on res.resourceid = image.resourceid
left join interestingfact as fact on res.resourceid = fact.resourceid
left join 
(
select res.resourceid,
-- resourcekeywords
   xmlelement(name resourcekeywords,
      xmlelement(name keywords,
         xmlagg(
            xmlelement(name term, term)
         )
      )
   ) as xml
from resource as res
join keyword on res.resourceid = keyword.resourceid
group by res.resourceid
) as keyword on res.resourceid = keyword.resourceid

left join 
(
select res.resourceid,
-- subjects
   xmlelement(name subjects,
      xmlagg(
         xmlelement(name subject, 
            xmlforest(category,subcategory,primarysubject as primary)
         )
      )
   ) as xml 

from resource as res
join subject on res.resourceid = subject.resourceid
group by res.resourceid

) as subject on res.resourceid = subject.resourceid


) as pre);

end
$$
language plpgsql;

select reconstructResources();


