drop table if exists resource cascade;

create table resource(
resourceId integer,
title text,
description text,
recordedDate date,
placedOnline date,
identifierUrl text,
publisherName text,
publisherAgency text,
primary key (resourceId)
)
;

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
