(:
der findes image tags kun  med tomt indhold
count(//resource/image[url ='' and caption ='' and alttext='' and sourceurl=''])
:)

(:
publisher har altid agency udfyldt, og ikke altid name
count(//resource/publisher[name ='' and agency = ''])
:)

(:interesing fact er ofte tom
//resource/interestingfact[url = '' and text = '']
:)

(: itemdate er altid udfyldt
count(//resource/itemdate[recordcreated = '' and placedonline = ''])
:)
(: identifier har altid en url
count(//resource/identifier[url = ''])
:)

(: resourcekeywords har altid værdi i term
count(//resource/resourcekeywords/keywords[term = ''])
:)
(: subjects har altid indhold
count(//resource/subjects/subject[category = '' and subcategory = '' and primary = ''])
:)