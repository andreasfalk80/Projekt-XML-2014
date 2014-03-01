drop table if exists resource cascade;

create table resource(
resourceId integer,
title text,
description text,
recordCreated date,
placedOnline date,
identifierUrl text,
publisherName text,
publisherAgency text,
FTS_index_col tsvector,
primary key (resourceId)
)
;

-- Trigger function for resource til full text search - automatisk tsvector!!
drop function if exists resource_trigger();
create function resource_trigger() returns trigger
as $$
declare

begin
  new.FTS_index_col := to_tsvector('english', new.description);
return new;
end
$$
language plpgsql;


create trigger resource_FTS_index_col 
before update of description,title or insert 
on resource 
for each row
execute procedure resource_trigger();

drop table if exists interestingFact cascade;
create table interestingFact(
interestingFactId serial,
resourceId integer,
url text,
text text,
primary key (interestingFactId),
foreign key (resourceId) references resource(resourceId) on delete cascade
)
;

drop table if exists keyword cascade;
create table keyword(
keywordId serial,
resourceId integer,
term text,
primary key (keywordId),
foreign key (resourceId) references resource(resourceId) on delete cascade
)
;

drop table if exists image cascade;
create table image(
imageId serial,
resourceId integer,
url text,
caption text,
sourceUrl text,
altText text,
primary key (imageId),
foreign key (resourceId) references resource(resourceId) on delete cascade
)
;

drop table if exists subject cascade;
create table subject(
subjectId serial,
resourceId integer,
category text,
subcategory text,
primarySubject text,
primary key (subjectId),
foreign key (resourceId) references resource(resourceId) on delete cascade
)
;

drop table if exists resource_xml cascade;
create table resource_xml(
id serial,
data xml,
primary key (id)
)
;



