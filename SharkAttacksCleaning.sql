/******************************************************************************************************************************************
TITLE: Shark Attacks Data Cleaning
AUTHOR: Sadie Hearn
DESCRIPTION: This script focuses on cleaning the data from the shark_attacks_raw table.
Skills Used- aggregate functions, window functions, updating columns, altering columns, CTEs 

******************************************************************************************************************************************/
-------------------------------------------------------------------------------------------------------------------------------------------
/*
Create a copy of the table to preserve the raw data. Data cleaning will take place in the new table

*/

select 
	*
into
	shark_attacks
from
	shark_attacks_raw
;

--Preliminary look at the table and all of its columns
select top 1000
	*
from
	shark_attacks
;

-------------------------------------------------------------------------------------------------------------------------------------------
/*
Thousands of rows in the table contain NULL values across all fields. These will be deleted to get rid of unnecessary clutter in the data
and improve runtime.

*/

delete
from
	shark_attacks
where
	CaseNumber is null
	and Date is null
	and Year is null
	and Type is null
	and Country is null
	and Area is null
	and Location is null
	and Activity is null
	and Name is null
	and Sex is null
	and Age is null
	and Injury is null
	and Fatal is null
	and Time is null
	and Species is null
	and InvestigatorOrSource is null
	and pdf is null
	and hrefFormula is null
	and href is null
	and CaseNumber1 is null
	and CaseNumber2 is null
	and OriginalOrder is null
;

-------------------------------------------------------------------------------------------------------------------------------------------
/*
CaseNumber, CaseNumber1, and CaseNumber2 Columns

There are several columns that seem to describe the case number. To determine if all of these columns are necessary, the CaseNumber, 
CaseNumber1, and CaseNumber2 will be compared.

*/

select
	Date
	, CaseNumber
	, CaseNumber1
	, CaseNumber2
from
	shark_attacks
where
	CaseNumber <> CaseNumber1
	or CaseNumber <> CaseNumber2
	or CaseNumber1 <> CaseNumber2
order by
	OriginalOrder
;

--Of all of the entries, only 15 rows show differences between the 3 case number columns. Of these 15 mismatches, they look to only differ
--by one digit across the 3 columns or by a misplaced character. Also the Date column most closely matches the CaseNumber column. The 
--CaseNumber1 and CaseNumber2 columns will be removed from the table
alter table
	shark_attacks
drop column
	CaseNumber1
	, CaseNumber2
;

--Some of the entries in the CaseNumber column contain incorrect characters (/ or - instead of .)
update
	shark_attacks
set
	CaseNumber = replace(replace(CaseNumber, '-', '.'), '/', '.')
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Date and Year Columns

*/

--Currently the Date column is the data type datetime, which is unnecessary here since the times in this column are listed as the default
--00:00:00. The data type date will be sufficient
alter table
	shark_attacks
alter column
	Date date
;

--There's a Date column as well as a Year column. These columns will be compared to check for descrepancies.
with date_vs_year as(
select
	CaseNumber
	, Date
	, datepart(year, Date) as date_year
	, Year
from
	shark_attacks
)

--select
--	*
--from
--	date_vs_year
--where
--	date_year <> Year
--;

--There are several hundred instances of the year entered in the Date column not matching the Year column. It can also be noted that and 
--the Year entry matches the first 4 digits of the CaseNumber. Also, the Date column contains dates that haven't happened yet. Comparing 
--the CaseNumber, Date, and Year columns, it looks like many of these errors came from using a '20' instead of a '19' in the Date column's 
--year (ex. 2029 instead of 1929) and similar errors. The Year column will be used to correct the Date column.
update
	date_vs_year
set
	Date = replace(Date, datepart(year, Date), Year)
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Type Column

*/

select
	Type
	, count(*) as count_incidents
from
	shark_attacks
group by
	Type
;

--There are two groups under the Type column entered as 'Boat' and 'Boating'. These will be combined into one group called 'Boating'.
update
	shark_attacks
set
	type = 'Boating'
where
	type = 'Boat'
;

--There is also a group called 'Invalid'. The name and injuries associated with this type will be checked to find out more about this 
--particular type entry. It is possible that an 'Invalid' type could be the same as a NULL.
select
	type
	, name
	, injury
from
	shark_attacks
where
	type = 'Invalid'
;
--After evaluating the information associated with 'Invalid' types, it has been determined that 'Invalid' was used for incidents that could
--not be confirmed if a shark was involved or in cases where provocation was ambiguous.

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Country Column

*/

select
	Country
	, count(*) as count_incidents
from
	shark_attacks
group by
	Country
order by
	Country
;

--Some countries have unnecessary spaces before or after the country name. These will be trimmed off.
update
	shark_attacks
set
	Country = trim(Country)
;

--Several of the entries include '?' indicating uncertainty of the country. The location and area will be pulled for these entries to try
--to confirm the location manually.
select
	Country
	, Location
	, Area
from	
	shark_attacks
where
	country like '%?'
;
--The locations and areas listed for these countries were either listed as NULL or were ambiguous. For clarity moving forward, the '?' will
--be replaced with '(uncomfirmed)'
update
	shark_attacks
set
	Country = replace(Country, '?', ' (unconfirmed)')
;

--There is a Country listed called 'St. Maartin'. This could be a misspelling of 'St. Maarten' or 'St. Martin'. The location and area will
--be pulled to try to confirm.
select
	Country
	, Location
	, Area
from
	shark_attacks
where
	Country = 'St. Maartin'
	or Country = 'St. Martin'
	or Country = 'St. Maarten'
;
--The location and area for St. Maartin are entered as 'Sunterra Beach' and 'Simpson Bay', respectively. This information confirms that
--'St. Maartin' should be spelled 'St. Maarten'
update
	shark_attacks
set
	Country = 'St. Maarten'
where
	Country = 'St. Maartin'
;

--'United Arab Emirates' is listed with and without the abbrevation 'UAE'. These will be changed so all of the entries for this country are
--listed as 'United Arab Emirates'
update
	shark_attacks
set
	Country = 'United Arab Emirates'
where
	Country = 'United Arab Emirates (UAE)'
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Area Column

*/

select
	Area
from
	shark_attacks
group by
	Area
;

--Trim off unnecessary spaces
update
	shark_attacks
set
	Area = trim(Area)
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Location Column

*/

select
	Location
from
	shark_attacks
group by
	Location
;

--Trim off unnecessary spaces
update
	shark_attacks
set
	Location = trim(Location)
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Activity Column

*/

select
	Activity
from
	shark_attacks
group by
	Activity
;

--Trim off unnecessary spaces
update
	shark_attacks
set
	Activity = trim(Activity)
;

--Replace any empty entries with NULL
update
	shark_attacks
set
	Activity = null
where
	Activity = ''
	or Activity = '.'
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Name Column

*/

select
	Name
from
	shark_attacks
group by
	Name
;

--Trim off unnecessary spaces
update
	shark_attacks
set
	Name = trim(Name)
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Sex Column

*/

select
	Sex
	, count(*) as count_incidents
from
	shark_attacks
group by
	Sex
;

--There are Sexes entered as 'lli', 'N', and '.' with one entry each. These records will be pulled to try to determine the sex of those
--involved.
select
	*
from
	shark_attacks
where
	sex = 'lli'
	or sex = 'N'
	or sex = '.'
;

--The 'N' and '.' will be changed to NULL. However, the case of Brian Kang (sex = 'lli') show the sex was 'M'.
update
	shark_attacks
set
	Sex = null
where
	Sex = 'N'
	or Sex = '.'
;

update
	shark_attacks
set
	Sex = 'M'
where
	Sex = 'lli'
;

--There are several hundred records with NULL listed as the Sex; However, the Name and Injury columns may be useful for finding this 
--missing information
select
	Sex
	, Name
	, Injury
from
	shark_attacks
where
	Sex is NULL
	and (Name like '%male%'
		or Name like '%boy%'
		or Name like '%girl%'
		or Injury like '%male%'
		or Injury like '%boy%'
		or Injury like '%girl%')
;
--Several records were found to have a NULL Sex entered but with Sex information listed under the Name or Injury. A few of these instances 
--listed the Sex as NULL because multiple victims were involved. Several of the instances, however, listed 'male' as the Name with no Sex 
--entered. These will be used to fill in some of the NULL values.
update
	shark_attacks
set
	Sex = 'M'
where
	Name = 'male'
	or Name = 'a male from the Second Seabee Battalion'
	or Name = 'schoolboy'
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Age Column

*/

select
	Age
	, count(*) as count_incidents
from
	shark_attacks
group by
	Age
;
--All of the ages were entered in the same manner. No cleaning necessary

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Injury Column

*/

select
	Injury
from
	shark_attacks
group by
	Injury
;
--A new column will be created to group injuries by general body part (Arms, Legs, Hands, Feet, Torso, Head, Pelvis).
--Start by finding the terms to group by
alter table
	shark_attacks
add
	BodyPartInjured nvarchar(255)
;

with injury_groups as(
select
	*
	, case
			when Injury like '%no injur%'
				or Injury like '%no inu%'
				or Injury like '%not injur%'
				or Injury like '%no attack%'
				or Injury like '%after he patted it on the head%'
										then 'No Injury'
			when Injury like '%head%' and Injury like '%shoulder%'
				or Injury like '%head%' and Injury like '%abdomen%'
				or Injury like '%head%' and Injury like '%stomach%'
				or Injury like '%head%' and Injury like '%chest%'
				or Injury like '%head%' and Injury like '%torso%'
				or Injury like '%head%' and Injury like '%back%'
				or Injury like '%head%' and Injury like '%rib%'
				or Injury like '%head%' and Injury like '%arm%'
				or Injury like '%head%' and Injury like '%shoulder%'
				or Injury like '%head%' and Injury like '%elbow%'
				or Injury like '%head%' and Injury like '%leg%'
				or Injury like '%head%' and Injury like '%calf%'
				or Injury like '%head%' and Injury like '%calves%'
				or Injury like '%head%' and Injury like '%thigh%'
				or Injury like '%head%' and Injury like '%shin%'
				or Injury like '%head%' and Injury like '%knee%'
				or Injury like '%head%' and Injury like '%hand%'
				or Injury like '%head%' and Injury like '%finger%'
				or Injury like '%head%' and Injury like '%wrist%'
				or Injury like '%head%' and Injury like '%foot%'
				or Injury like '%head%' and Injury like '%feet%'
				or Injury like '%head%' and Injury like '%toe%'
				or Injury like '%head%' and Injury like '%ankle%'
				or Injury like '%head%' and Injury like '%pelvis%'
				or Injury like '%head%' and Injury like '%buttock%'
				or Injury like '%head%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%head%' and Injury like '%groin%'
				or Injury like '%face%' and Injury like '%shoulder%'
				or Injury like '%face%' and Injury like '%abdomen%'
				or Injury like '%face%' and Injury like '%stomach%'
				or Injury like '%face%' and Injury like '%chest%'
				or Injury like '%face%' and Injury like '%torso%'
				or Injury like '%face%' and Injury like '%back%'
				or Injury like '%face%' and Injury like '%rib%'
				or Injury like '%face%' and Injury like '%arm%'
				or Injury like '%face%' and Injury like '%shoulder%'
				or Injury like '%face%' and Injury like '%elbow%'
				or Injury like '%face%' and Injury like '%leg%'
				or Injury like '%face%' and Injury like '%calf%'
				or Injury like '%face%' and Injury like '%calves%'
				or Injury like '%face%' and Injury like '%thigh%'
				or Injury like '%face%' and Injury like '%shin%'
				or Injury like '%face%' and Injury like '%knee%'
				or Injury like '%face%' and Injury like '%hand%'
				or Injury like '%face%' and Injury like '%finger%'
				or Injury like '%face%' and Injury like '%wrist%'
				or Injury like '%face%' and Injury like '%foot%'
				or Injury like '%face%' and Injury like '%feet%'
				or Injury like '%face%' and Injury like '%toe%'
				or Injury like '%face%' and Injury like '%ankle%'
				or Injury like '%face%' and Injury like '%pelvis%'
				or Injury like '%face%' and Injury like '%buttock%'
				or Injury like '%face%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%face%' and Injury like '%groin%'
				or Injury like '%skull%' and Injury like '%shoulder%'
				or Injury like '%skull%' and Injury like '%abdomen%'
				or Injury like '%skull%' and Injury like '%stomach%'
				or Injury like '%skull%' and Injury like '%chest%'
				or Injury like '%skull%' and Injury like '%torso%'
				or Injury like '%skull%' and Injury like '%back%'
				or Injury like '%skull%' and Injury like '%rib%'
				or Injury like '%skull%' and Injury like '%arm%'
				or Injury like '%skull%' and Injury like '%shoulder%'
				or Injury like '%skull%' and Injury like '%elbow%'
				or Injury like '%skull%' and Injury like '%leg%'
				or Injury like '%skull%' and Injury like '%calf%'
				or Injury like '%skull%' and Injury like '%calves%'
				or Injury like '%skull%' and Injury like '%thigh%'
				or Injury like '%skull%' and Injury like '%shin%'
				or Injury like '%skull%' and Injury like '%knee%'
				or Injury like '%skull%' and Injury like '%hand%'
				or Injury like '%skull%' and Injury like '%finger%'
				or Injury like '%skull%' and Injury like '%wrist%'
				or Injury like '%skull%' and Injury like '%foot%'
				or Injury like '%skull%' and Injury like '%feet%'
				or Injury like '%skull%' and Injury like '%toe%'
				or Injury like '%skull%' and Injury like '%ankle%'
				or Injury like '%skull%' and Injury like '%pelvis%'
				or Injury like '%skull%' and Injury like '%buttock%'
				or Injury like '%skull%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%skull%' and Injury like '%groin%'
				or Injury like '%neck%' and Injury like '%shoulder%'
				or Injury like '%neck%' and Injury like '%abdomen%'
				or Injury like '%neck%' and Injury like '%stomach%'
				or Injury like '%neck%' and Injury like '%chest%'
				or Injury like '%neck%' and Injury like '%torso%'
				or Injury like '%neck%' and Injury like '%back%'
				or Injury like '%neck%' and Injury like '%rib%'
				or Injury like '%neck%' and Injury like '%arm%'
				or Injury like '%neck%' and Injury like '%shoulder%'
				or Injury like '%neck%' and Injury like '%elbow%'
				or Injury like '%neck%' and Injury like '%leg%'
				or Injury like '%neck%' and Injury like '%calf%'
				or Injury like '%neck%' and Injury like '%calves%'
				or Injury like '%neck%' and Injury like '%thigh%'
				or Injury like '%neck%' and Injury like '%shin%'
				or Injury like '%neck%' and Injury like '%knee%'
				or Injury like '%neck%' and Injury like '%hand%'
				or Injury like '%neck%' and Injury like '%finger%'
				or Injury like '%neck%' and Injury like '%wrist%'
				or Injury like '%neck%' and Injury like '%foot%'
				or Injury like '%neck%' and Injury like '%feet%'
				or Injury like '%neck%' and Injury like '%toe%'
				or Injury like '%neck%' and Injury like '%ankle%'
				or Injury like '%neck%' and Injury like '%pelvis%'
				or Injury like '%neck%' and Injury like '%buttock%'
				or Injury like '%neck%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%neck%' and Injury like '%groin%'
				or Injury like '%abdomen%' and Injury like '%arm%'
				or Injury like '%abdomen%' and Injury like '%shoulder%'
				or Injury like '%abdomen%' and Injury like '%elbow%'
				or Injury like '%abdomen%' and Injury like '%leg%'
				or Injury like '%abdomen%' and Injury like '%calf%'
				or Injury like '%abdomen%' and Injury like '%calves%'
				or Injury like '%abdomen%' and Injury like '%thigh%'
				or Injury like '%abdomen%' and Injury like '%shin%'
				or Injury like '%abdomen%' and Injury like '%knee%'
				or Injury like '%abdomen%' and Injury like '%hand%'
				or Injury like '%abdomen%' and Injury like '%finger%'
				or Injury like '%abdomen%' and Injury like '%wrist%'
				or Injury like '%abdomen%' and Injury like '%foot%'
				or Injury like '%abdomen%' and Injury like '%feet%'
				or Injury like '%abdomen%' and Injury like '%toe%'
				or Injury like '%abdomen%' and Injury like '%ankle%'
				or Injury like '%abdomen%' and Injury like '%pelvis%'
				or Injury like '%abdomen%' and Injury like '%buttock%'
				or Injury like '%abdomen%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%abdomen%' and Injury like '%groin%'
				or Injury like '%stomach%' and Injury like '%arm%'
				or Injury like '%stomach%' and Injury like '%shoulder%'
				or Injury like '%stomach%' and Injury like '%elbow%'
				or Injury like '%stomach%' and Injury like '%leg%'
				or Injury like '%stomach%' and Injury like '%calf%'
				or Injury like '%stomach%' and Injury like '%calves%'
				or Injury like '%stomach%' and Injury like '%thigh%'
				or Injury like '%stomach%' and Injury like '%shin%'
				or Injury like '%stomach%' and Injury like '%knee%'
				or Injury like '%stomach%' and Injury like '%hand%'
				or Injury like '%stomach%' and Injury like '%finger%'
				or Injury like '%stomach%' and Injury like '%wrist%'
				or Injury like '%stomach%' and Injury like '%foot%'
				or Injury like '%stomach%' and Injury like '%feet%'
				or Injury like '%stomach%' and Injury like '%toe%'
				or Injury like '%stomach%' and Injury like '%ankle%'
				or Injury like '%stomach%' and Injury like '%pelvis%'
				or Injury like '%stomach%' and Injury like '%buttock%'
				or Injury like '%stomach%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%stomach%' and Injury like '%groin%'
				or Injury like '%chest%' and Injury like '%arm%'
				or Injury like '%chest%' and Injury like '%shoulder%'
				or Injury like '%chest%' and Injury like '%elbow%'
				or Injury like '%chest%' and Injury like '%leg%'
				or Injury like '%chest%' and Injury like '%calf%'
				or Injury like '%chest%' and Injury like '%calves%'
				or Injury like '%chest%' and Injury like '%thigh%'
				or Injury like '%chest%' and Injury like '%shin%'
				or Injury like '%chest%' and Injury like '%knee%'
				or Injury like '%chest%' and Injury like '%hand%'
				or Injury like '%chest%' and Injury like '%finger%'
				or Injury like '%chest%' and Injury like '%wrist%'
				or Injury like '%chest%' and Injury like '%foot%'
				or Injury like '%chest%' and Injury like '%feet%'
				or Injury like '%chest%' and Injury like '%toe%'
				or Injury like '%chest%' and Injury like '%ankle%'
				or Injury like '%chest%' and Injury like '%pelvis%'
				or Injury like '%chest%' and Injury like '%buttock%'
				or Injury like '%chest%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%chest%' and Injury like '%groin%'
				or Injury like '%torso%' and Injury like '%arm%'
				or Injury like '%torso%' and Injury like '%shoulder%'
				or Injury like '%torso%' and Injury like '%elbow%'
				or Injury like '%torso%' and Injury like '%leg%'
				or Injury like '%torso%' and Injury like '%calf%'
				or Injury like '%torso%' and Injury like '%calves%'
				or Injury like '%torso%' and Injury like '%thigh%'
				or Injury like '%torso%' and Injury like '%shin%'
				or Injury like '%torso%' and Injury like '%knee%'
				or Injury like '%torso%' and Injury like '%hand%'
				or Injury like '%torso%' and Injury like '%finger%'
				or Injury like '%torso%' and Injury like '%wrist%'
				or Injury like '%torso%' and Injury like '%foot%'
				or Injury like '%torso%' and Injury like '%feet%'
				or Injury like '%torso%' and Injury like '%toe%'
				or Injury like '%torso%' and Injury like '%ankle%'
				or Injury like '%torso%' and Injury like '%pelvis%'
				or Injury like '%torso%' and Injury like '%buttock%'
				or Injury like '%torso%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%torso%' and Injury like '%groin%'
				or Injury like '%back%' and Injury like '%arm%'
				or Injury like '%back%' and Injury like '%shoulder%'
				or Injury like '%back%' and Injury like '%elbow%'
				or Injury like '%back%' and Injury like '%leg%'
				or Injury like '%back%' and Injury like '%calf%'
				or Injury like '%back%' and Injury like '%calves%'
				or Injury like '%back%' and Injury like '%thigh%'
				or Injury like '%back%' and Injury like '%shin%'
				or Injury like '%back%' and Injury like '%knee%'
				or Injury like '%back%' and Injury like '%hand%'
				or Injury like '%back%' and Injury like '%finger%'
				or Injury like '%back%' and Injury like '%wrist%'
				or Injury like '%back%' and Injury like '%foot%'
				or Injury like '%back%' and Injury like '%feet%'
				or Injury like '%back%' and Injury like '%toe%'
				or Injury like '%back%' and Injury like '%ankle%'
				or Injury like '%back%' and Injury like '%pelvis%'
				or Injury like '%back%' and Injury like '%buttock%'
				or Injury like '%back%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%back%' and Injury like '%groin%'
				or Injury like '%arm%' and Injury like '%leg%'
				or Injury like '%arm%' and Injury like '%calf%'
				or Injury like '%arm%' and Injury like '%calves%'
				or Injury like '%arm%' and Injury like '%thigh%'
				or Injury like '%arm%' and Injury like '%shin%'
				or Injury like '%arm%' and Injury like '%knee%'
				or Injury like '%arm%' and Injury like '%hand%'
				or Injury like '%arm%' and Injury like '%finger%'
				or Injury like '%arm%' and Injury like '%wrist%'
				or Injury like '%arm%' and Injury like '%foot%'
				or Injury like '%arm%' and Injury like '%feet%'
				or Injury like '%arm%' and Injury like '%toe%'
				or Injury like '%arm%' and Injury like '%ankle%'
				or Injury like '%arm%' and Injury like '%pelvis%'
				or Injury like '%arm%' and Injury like '%buttock%'
				or Injury like '%arm%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%arm%' and Injury like '%groin%'
				or Injury like '%shoulder%' and Injury like '%leg%'
				or Injury like '%shoulder%' and Injury like '%calf%'
				or Injury like '%shoulder%' and Injury like '%calves%'
				or Injury like '%shoulder%' and Injury like '%thigh%'
				or Injury like '%shoulder%' and Injury like '%shin%'
				or Injury like '%shoulder%' and Injury like '%knee%'
				or Injury like '%shoulder%' and Injury like '%hand%'
				or Injury like '%shoulder%' and Injury like '%finger%'
				or Injury like '%shoulder%' and Injury like '%wrist%'
				or Injury like '%shoulder%' and Injury like '%foot%'
				or Injury like '%shoulder%' and Injury like '%feet%'
				or Injury like '%shoulder%' and Injury like '%toe%'
				or Injury like '%shoulder%' and Injury like '%ankle%'
				or Injury like '%shoulder%' and Injury like '%pelvis%'
				or Injury like '%shoulder%' and Injury like '%buttock%'
				or Injury like '%shoulder%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%shoulder%' and Injury like '%groin%'
				or Injury like '%leg%' and Injury like '%hand%'
				or Injury like '%leg%' and Injury like '%finger%'
				or Injury like '%leg%' and Injury like '%wrist%'
				or Injury like '%leg%' and Injury like '%foot%'
				or Injury like '%leg%' and Injury like '%feet%'
				or Injury like '%leg%' and Injury like '%toe%'
				or Injury like '%leg%' and Injury like '%ankle%'
				or Injury like '%leg%' and Injury like '%pelvis%'
				or Injury like '%leg%' and Injury like '%buttock%'
				or Injury like '%leg%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%leg%' and Injury like '%groin%'
				or Injury like '%thigh%' and Injury like '%hand%'
				or Injury like '%thigh%' and Injury like '%finger%'
				or Injury like '%thigh%' and Injury like '%wrist%'
				or Injury like '%thigh%' and Injury like '%foot%'
				or Injury like '%thigh%' and Injury like '%feet%'
				or Injury like '%thigh%' and Injury like '%toe%'
				or Injury like '%thigh%' and Injury like '%ankle%'
				or Injury like '%thigh%' and Injury like '%pelvis%'
				or Injury like '%thigh%' and Injury like '%buttock%'
				or Injury like '%thigh%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%thigh%' and Injury like '%groin%'
				or Injury like '%calf%' and Injury like '%hand%'
				or Injury like '%calf%' and Injury like '%finger%'
				or Injury like '%calf%' and Injury like '%wrist%'
				or Injury like '%calf%' and Injury like '%foot%'
				or Injury like '%calf%' and Injury like '%feet%'
				or Injury like '%calf%' and Injury like '%toe%'
				or Injury like '%calf%' and Injury like '%ankle%'
				or Injury like '%calf%' and Injury like '%pelvis%'
				or Injury like '%calf%' and Injury like '%buttock%'
				or Injury like '%calf%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%calf%' and Injury like '%groin%'
				or Injury like '%shin%' and Injury like '%hand%'
				or Injury like '%shin%' and Injury like '%finger%'
				or Injury like '%shin%' and Injury like '%wrist%'
				or Injury like '%shin%' and Injury like '%foot%'
				or Injury like '%shin%' and Injury like '%feet%'
				or Injury like '%shin%' and Injury like '%toe%'
				or Injury like '%shin%' and Injury like '%ankle%'
				or Injury like '%shin%' and Injury like '%pelvis%'
				or Injury like '%shin%' and Injury like '%buttock%'
				or Injury like '%shin%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%shin%' and Injury like '%groin%'
				or Injury like '%knee%' and Injury like '%hand%'
				or Injury like '%knee%' and Injury like '%finger%'
				or Injury like '%knee%' and Injury like '%wrist%'
				or Injury like '%knee%' and Injury like '%foot%'
				or Injury like '%knee%' and Injury like '%feet%'
				or Injury like '%knee%' and Injury like '%toe%'
				or Injury like '%knee%' and Injury like '%ankle%'
				or Injury like '%knee%' and Injury like '%pelvis%'
				or Injury like '%knee%' and Injury like '%buttock%'
				or Injury like '%knee%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%knee%' and Injury like '%groin%'
				or Injury like '%hand%' and Injury like '%foot%'
				or Injury like '%hand%' and Injury like '%feet%'
				or Injury like '%hand%' and Injury like '%toe%'
				or Injury like '%hand%' and Injury like '%ankle%'
				or Injury like '%hand%' and Injury like '%pelvis%'
				or Injury like '%hand%' and Injury like '%buttock%'
				or Injury like '%hand%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%hand%' and Injury like '%groin%'
				or Injury like '%finger%' and Injury like '%foot%'
				or Injury like '%finger%' and Injury like '%feet%'
				or Injury like '%finger%' and Injury like '%toe%'
				or Injury like '%finger%' and Injury like '%ankle%'
				or Injury like '%finger%' and Injury like '%pelvis%'
				or Injury like '%finger%' and Injury like '%buttock%'
				or Injury like '%finger%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%finger%' and Injury like '%groin%'
				or Injury like '%wrist%' and Injury like '%foot%'
				or Injury like '%wrist%' and Injury like '%feet%'
				or Injury like '%wrist%' and Injury like '%toe%'
				or Injury like '%wrist%' and Injury like '%ankle%'
				or Injury like '%wrist%' and Injury like '%pelvis%'
				or Injury like '%wrist%' and Injury like '%buttock%'
				or Injury like '%wrist%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%wrist%' and Injury like '%groin%'
				or Injury like '%foot%' and Injury like '%pelvis%'
				or Injury like '%foot%' and Injury like '%buttock%'
				or Injury like '%foot%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%foot%' and Injury like '%groin%'
				or Injury like '%feet%' and Injury like '%pelvis%'
				or Injury like '%feet%' and Injury like '%buttock%'
				or Injury like '%feet%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%feet%' and Injury like '%groin%'
				or Injury like '%toe%' and Injury like '%pelvis%'
				or Injury like '%toe%' and Injury like '%buttock%'
				or Injury like '%toe%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%toe%' and Injury like '%groin%'
				or Injury like '%ankle%' and Injury like '%pelvis%'
				or Injury like '%ankle%' and Injury like '%buttock%'
				or Injury like '%ankle%' and Injury like '%hip%' and Injury not like '%ship%'
				or Injury like '%ankle%' and Injury like '%groin%'
										then 'Multiple Body Parts Injured'
			when Injury not like '%recovered%'
				and (Injury like '%head%'
				or Injury like '%face%'
				or Injury like '%facial%'
				or Injury like '%scalp%'
				or Injury like '%skull%'
				or Injury like '%scull%'
				or Injury like '%neck%'
				or Injury like '%nose%'
				or Injury like '%lip%'
				or Injury like '%cheek%'
				or Injury like '%eye%'
				or Injury like '%jaw%')
										then 'Head'
			when Injury not like '%recovered%'
				and (Injury like '%abdomen%'
				or Injury like '%stomach%'
				or Injury like '%chest%'
				or Injury like '%torso%'
				or Injury like '%back%'
				or Injury like '%rib%')
										then 'Torso'
			when Injury not like '%recovered%'
				and (Injury like '%arm%'
				or Injury like '%foream%'
				or Injury like '%bicep%'
				or Injury like '%shoulder%'
				or Injury like '%elbow%'
				or Injury like '%radius%'
				or Injury like '%ulna%'
				or Injury = 'Am lacerated')
										then 'Arm(s)'
			when Injury not like '%recovered%'
				and (Injury like '%leg%'
				or Injury like '%thigh%'
				or Injury like '%calf%'
				or Injury like '%calves%'
				or Injury like '%shin%'
				or Injury like '%knee%'
				or Injury like '%hamstring%'
				or Injury like '%femur%'
				or Injury like '%femoral%'
				or Injury = 'Left eg bitten PROVOKED INCIDENT')
										then 'Leg(s)'
			when Injury not like '%recovered%'
				and Injury not like '%threw up his hands%'
				and Injury not like '%found in a shark%'
				and (Injury like '%hand%'
				or Injury like '%finger%'
				or Injury like '%wrist%'
				or Injury like '%thumb%'
				or Injury like '%palm%')
										then 'Hand(s)'
			when Injury not like '%recovered%'
				and (Injury like '%foot%'
				or Injury like '%feet%'
				or Injury like '%toe%'
				or Injury like '%ankle%'
				or Injury like '%achilles tendon%'
				or Injury like '%heel%')
										then 'Foot'
			when Injury not like '%recovered%'
				and (Injury like '%pelvis%'
				or Injury like '%buttock%'
				or Injury like '%hip%'and Injury not like '%ship%'
				or Injury like '%groin%'
				or Injury like '%penis%')
										then 'Pelvis'
			else null
		end as body_part_injured
from
	shark_attacks
)
update
	injury_groups
set
	BodyPartInjured = body_part_injured
;
--Now that the new column is created, its NULL entries can be used to help weed through any body injuries that may have been missed
select
	Injury
from
	shark_attacks
where
	BodyPartInjured is null
	and Injury not like '%fatal%'
	and Injury not like '%no details%'
	and Injury not like '%remains%'
group by
	Injury
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Fatal Column


*/

select
	Fatal
	, count(*) as count_incidents
from
	shark_attacks
group by
	Fatal
;
--A few of the columns can be grouped such as 'N' and ' N' (unnecessary space) and the 'F' and 'Y' column
update
	shark_attacks
set
	Fatal = trim(Fatal)
;

update
	shark_attacks
set
	Fatal = 'Y'
where
	Fatal = 'F'
;

--One entry lists '2017' under Fatal. This entry will be checked.
select
	*
from
	shark_attacks
where
	Fatal = '2017'
;
--This attack was found to be non-fatal
update
	shark_attacks
set
	Fatal = 'N'
where
	Fatal = '2017'
;

--There are several hundred records with NULL or 'UNKNOWN' listed for Fatal. Again, the Injury column may be useful for finding this 
--missing information.
select
	Fatal
	, Injury
	, BodyPartInjured
from
	shark_attacks
where
	(Fatal is NULL
		or Fatal = 'Unknown')
	and (Injury like '%fatal%'
		or Injury like '%remains%'
		or BodyPartInjured = 'No Injury')
;
--Several entries were found to be fatal or non-fatal from the Injury column, despite having a NULL or 'UNKNOWN' fatal value. These will be
--used to fill in some of the missing data
update
	shark_attacks
set
	Fatal = 'Y'
where
	Fatal is NULL
	and (Injury like '%fatal%'
		or Injury like '%remains%')
;

update
	shark_attacks
set
	Fatal = 'N'
where
	(Fatal is NULL
		or Fatal = 'Unknown')
	and BodyPartInjured = 'No Injury'
;

--Check for inconsistencies between the BodyPartInjured column and Fatal column
select
	*
from
	shark_attacks
where
	BodyPartInjured = 'No Injury'
	and Fatal = 'Y'
;
--There is one entry that shows no injury occured, yet the attack was fatal. After checking information on the incident, it was confirmed
--that the incident was in fact non-fatal. This will be updated in the table
update
	shark_attacks
set
	Fatal = 'N'
where
	CaseNumber = '1894.07.15.R'
	and Name = 'la Badine, Hyères,'
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Time Column

*/

select
	Time
from
	shark_attacks
;
--The times follow several different formats. There are exact times reported, ranges, and descriptions. For consitency, times reported will
--follow the format hh:mm. Start by replacing 'h' and 'j' with ':'. This will also remove the h's and j's in any of the time descriptions
--as well but these will be cleaned later anyways.
update
	shark_attacks
set
	Time = replace(replace(Time, 'h', ':'), 'j', ':')
;

--Find remaining times reported with improper formatting
select
	Time
from
	shark_attacks
where
	len(Time) <> 5 --properly formatted times should contain 5 characters (hh:mm)
	and Time not like '%[abcdefghijklmnopqrstuvwxyz]%' --for now entries with letters will not be looked at, these will be evaluated
														--later when looking at time descriptions
;
--Some of the times reported follow the format h:mm. A 0 will be added to these times
with time_digits as(
select
	Time
	, '0' + Time as updated_time
from
	shark_attacks
where
	(Time not like '%:%'
		and len(Time) = 3) --times which only contain 3 digits with no :
	or (Time like '%:%'
		and len(Time) = 4) --times which only contain 3 digits including :
)
update
	time_digits
set
	Time = updated_time
;
--Now that all the times reported contain 4 digits, a ':' will be inserted where it is missing.
with time_colon as(
select
	Time
	, substring(Time, 1, 2) + ':' + substring(Time, 3, 4) as updated_time
from
	shark_attacks
where
	Time not like '%:%'
	and Time not like '%[abcdefghijklmnopqrstuvwxyz]%'
)
update
	time_colon
set
	Time = updated_time
;

--Trim unnecessary leading and trailing characters, including spaces
with time_characters as(
select
	Time
	, trim(trim(':' from trim('?' from Time))) as updated_time
from 
	shark_attacks
where
	len(Time) != 5
	and Time not like '%[abcdefghijklmnopqrstuvwxyz]%'
)
update
	time_characters
set
	Time = updated_time
;

--There are several time descriptions where the exact time was not reported. For easier grouping, these values will be condensed into
--'Morning', 'Afternoon', and 'Evening'. Any values listed as '-', 'X', or similar single characters will be replaced with NULL.
--Start by finding descriptions to group into categories
select
	Time
from
	shark_attacks
where
	--Time not like '%[0123456789]%'
	--Time like '%or%'
	--Time like '%-%'
	--Time like '%/%'
	Time like '%>%'
	or Time like '%<%'
group by
	Time
;

--There are a few time descriptions which reference other incidents. These will be checked to confirm when they occured.
select
	*
from 
	shark_attacks
where
	--Name like '%Opperman%'
	--or Time like '%Opperman%'
	--CaseNumber = '1992.07.08.a'
	--or Time like '%1992.07.08.a%'
	CaseNumber = '2000.08.21'
	or Time like '%2000.08.21%'
;
--Group by time description
with time_groups as(
select
	*
	, case
			when Time = 'AM' 
				or Time = 'A.M.'
				or Time like '%daybreak%'
				or Time like '%dawn%'
				or Time like '%morning%'
				or Time like '%before 12%'
				or Time like '%before noon%'
				or Time like '%before 11%'
				or Time = 'Before 07:00'
				or Time = 'Before 10:30'
				or Time = 'Prior to 10:37'
				or Time like '%11:01 -time of%'
				or Time = 'After 04:00'
				or Time = 'Between 05:00 and 08:00'
				or Time = 'Between 06:00 & 07:20'
				or Time = 'Between 11:00 & 12:00'
				or Time like '%Sometime between 06%'
				or Time like '%1992.07.08.a%'
				or Time = '<07:30'
				or Time = '>06:45'
				or Time = '>08:00'
										then 'Morning'
			when Time like '%afternoon%'
				or Time = 'After noon'
				or Time like '%afternon%'
				or Time like '%Midday%'
				or Time like '%lunc:%'
				or Time = 'P.M.'
				or Time like '%after 12%'
				or Time like '%before 13%'
				or Time like '%or 14:00%'
				or Time like '%or 13:30%'
				or Time = '15:00 or 15:45'
				or Time like '%Opperman%'
				or Time = '12:00 to 14:00'
				or Time like '%at 03:10%'
				or Time = 'Daytime'
				or Time = '>12:00'
				or Time = '>14:30'
										then 'Afternoon'
			when Time like '%dark%'
				or Time like '%dusk%'
				or Time like '%evening%'
				or Time like '%sundown%'
				or Time like '%sunset%'
				or Time like '%nig:t%'
				or Time = '16:30 or 18:00'
				or Time = '17:00 or 17:40'
				or Time = '18:15 to 21:30'
				or Time = '>17:00'
				or Time = '>17:30'
										then 'Evening'
			when Time = 'Noon'
										then '12:00'
			when Time = '8:04 PM'
										then '20:04'
			when Time = '--'
				or Time = 'X'
				or Time = ' '
				or Time = ''
				or Time = ':'
				or Time like '%fatal%'
				or Time like '%2000.08.21%'
										then null
			else Time
		end as updated_time
from
	shark_attacks
)
update
	time_groups
set
	Time = updated_time
;

--The times listed in ranges are all within an hour of each other so these ranges will be trimmed to just take the first time listed
--in the range.
with time_range as(
select
	Time
	, substring(Time, 1, 5) as updated_time
from
	shark_attacks
where
	Time like '%-%'
	or Time like '%/%'
)
update
	time_range
set
	Time = updated_time
;

--A few of the remaining times contain a repeated digit from the hour (hh:hmm). This repeated digit will be deleted
with time_repeated_digit as(
select
	time
	, substring(Time, 1, 3) + substring(Time, 5, 6) as updated_time
from
	shark_attacks
where
	len(Time) <> 5
	and Time <> 'Morning'
	and Time <> 'Afternoon'
	and Time <> 'Evening'
)
update
	time_repeated_digit
set
	Time = updated_time
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
Species Column

*/

select
	Species
from
	shark_attacks
group by
	Species
;

--Some of the entries need to be trimmed of leading or trailing spaces
update
	shark_attacks
set
	Species = trim(Species)
;

--Empty entries in the Species column will be replaced with NULL
update
	shark_attacks
set
	Species = null
where
	Species = ' '
	or Species = ''
;

--The Species column actually lists the species (if identified), the size of the shark, and/or a description of the shark. For analysis,
--a new column will be made to list only the Species Identified. The current Species column will be renamed to SharkDescription and will
--be kept to provide details of the shark(s) involved in the attack.
alter table
	shark_attacks
add
	SpeciesIdentified nvarchar(255)
;

--Group species
with shark_species as(
select
	*
	, case
		when SharkDescription like '% or %'and SharkDescription not like '%Rhizoprionodon or Loxodon%' 
			or SharkDescription like '%(or %'
												then 'Unconfirmed- See Shark Description'
		when SharkDescription like '%angel%'
												then 'Angel Shark'

		when SharkDescription like '%basking%'
												then 'Basking Shark'
		when SharkDescription like '%blacktail%'
			or SharkDescription like '%grey reef%'
			or SharkDescription like '%gray reef%'
												then 'Blacktail/Gray Reef Shark'
		when SharkDescription like '%blacktip%'
												then 'Blacktip Reef Shark'
		when SharkDescription like '%blue%'
			and SharkDescription not like '%pointer%'
												then 'Blue Shark'
		when SharkDescription like '%blue pointer%'
			or SharkDescription like '%bonit%'
			or SharkDescription like '%shortfin mako%'
												then 'Blue Pointer/Bonito/Shortfin Mako Shark'
		when SharkDescription like '%broadnose%'
			or SharkDescription like '%sevengill%'
			or SharkDescription like '%seven-gill%'
			or SharkDescription like '%7 gill%'
			or SharkDescription like '%7-gill%'
												then 'Broadnose Sevengill Shark'
		when SharkDescription like '%bronze%'
			or SharkDescription like '%copper%'
			or SharkDescription like '%whaler%'
												then 'Bronze Whaler/Copper/Narrowtooth Shark'
		when SharkDescription like '%bull%'
			or SharkDescription like '%zambe%'
			or SharkDescription like '%leucas%'
												then 'Bull/Zambezi Shark'
		when SharkDescription like '%Caribbean%'
												then 'Caribbean Reef Shark'
		when SharkDescription like '%carpet%'
			or SharkDescription like '%wobbegong%'
												then 'Carpet Shark/Wobbegong'
		when SharkDescription like '%cow%'
												then 'Cow Shark'
		when SharkDescription like '%dog%'
												then 'Dogfish Shark'
		when SharkDescription like '%dusky%'
												then 'Dusky Shark'
		when SharkDescription like '%galapagos%'
												then 'Galapagos Shark'
		when SharkDescription like '%goblin%'
												then 'Goblin Shark'
		when SharkDescription like '%gray nurse%'
			or SharkDescription like '%grey nurse%'
			or SharkDescription like '%sand%' and SharkDescription not like '%bar%'
			or SharkDescription like '%ragged%'
												then 'Sand Tiger/Gray Nurse/Raggedtooth Shark'
		when SharkDescription like '%hammerhead%'
												then 'Hammerhead Shark'
		when SharkDescription like '%horn%'
												then 'Horn Shark'
		when SharkDescription like '%ganges%'
			or SharkDescription like '%gangeticus%'
												then 'Ganges Shark'
		when SharkDescription like '%lemon%'
			and SharkDescription not like '% or %'
												then 'Lemon Shark'
		when SharkDescription like '%leopard%'
												then 'Leopard Shark'
		when SharkDescription like '%longfin mako%'
												then 'Longfin Mako Shark'
		when SharkDescription like '%mako%'
			and SharkDescription not like '%shortfin%'
			and SharkDescription not like '%longfin%'
												then 'Mako Shark'
		when SharkDescription like '%nurse%'
												then 'Nurse Shark'
		when SharkDescription like '%oceanic%'
												then 'Oceanic Whitetip Shark'
		when SharkDescription like '%porbeagle%'
												then 'Porbeagle Shark'
		when SharkDescription like '%reef%'
			and SharkDescription not like '%blacktip%'
			and SharkDescription not like '%grey%'
			and SharkDescription not like '%gray%'
			and SharkDescription not like '%whitetip%'
			and SharkDescription not like '%galapogos%'
			and SharkDescription not like '%caribbean%'
												then 'Reef Shark'
		when SharkDescription like '%Salmon%'
												then 'Salmon Shark'
		when SharkDescription like '%sandbar%'
			or SharkDescription like '%brown shark%'
			or SharkDescription like '%thickskin%'
												then 'Sandbar/Brown/Thickskin Shark'
		when SharkDescription like '%shovel%'
												then 'Shovenose Shark'
		when SharkDescription like '%silky%'
												then 'Silky Shark'
		when SharkDescription like '%silvertip%'
			or SharkDescription like '%albimarginatus%'
												then 'Silvertip Shark'
		when SharkDescription like '%spinner%'
												then 'Spinner Shark'
		when SharkDescription like '%spurdog%'
												then 'Spurdog'
		when SharkDescription like '%tawn%'
												then 'Tawny Nurse Shark'
		when SharkDescription like '%tiger shark%'
												then 'Tiger Shark'
		when SharkDescription like '%white shark%'
												then 'Great White Shark'
		when SharkDescription like '%whitetip%'
			or SharkDescription like '%whtietip%'
												then 'Whitetip Reef Shark'
		when SharkDescription like '%gummy%'
												then 'Gummy Shark'
		when SharkDescription like '%whiptail%'
			or SharkDescription like '%thresher%'
												then 'Whiptail Shark/Common Thresher'
		when SharkDescription like '%catshark%'
			or SharkDescription like '%cat shark%'
												then 'Catshark'
		when SharkDescription like '%soupfin%'
												then 'Soupfin Shark'
		when SharkDescription like '%starry smooth%'
												then 'Starry Smoothhound Shark'
		when SharkDescription like '%whale shark%'
												then 'Whale Shark'
		else 'Not Specified'
	end as species	
from
	shark_attacks
)
update
	shark_species
set
	SpeciesIdentified = species
	
;
	

--------------------------------------------------------------------------------------------------------------------------------------------
/*
After viewing the Type, Activity, Injury, and SharkDescription columns, it looks like many of the entries were not confirmed to actually be 
shark attacks. Instead, these entries may have have other predator involvement, hoaxes, post-mortem scavenging, or other non-shark attack 
related incidents. For accurate data analysis of shark attacks, these records will be removed.

*/

delete from
	shark_attacks
where
	Injury like '%stingray%'
	or Injury like '%question%'
	or Injury like '%hoax%'
	or Injury like '%not confirm%'
	or Injury like '%shark involv%'
	or Injury like '%mortem%'
	or Injury like '%scaveng%'
	or Injury like '%coral%'
	or Injury like '%not cause%'
	or Injury like '%sharks fed%'
	or Injury like '%no attack%'
	or Injury = 'Later found to be fixtion, never happened'
	or Injury = 'Sharks were numerous & took corpses but made no attempts to harm the survivors.'
	or SharkDescription like '%stingray%'
	or SharkDescription like '%question%'
	or SharkDescription like '%hoax%'
	or SharkDescription like '%not confirm%'
	or SharkDescription like '%unconfirmed attack%'
	or SharkDescription like '%shark invo%'
	or SharkDescription like '%not a shark%'
	or SharkDescription = 'Not authenticated'
	or Activity = 'Suicide'
;

--------------------------------------------------------------------------------------------------------------------------------------------
/*
InvestigatorOrSource Column


*/

select
	InvestigatorOrSource
from
	shark_attacks
;
--This column contains the investigator who reported on the incident or the source the report was pulled from. 

--For consistent formatting, any excess spaces will be trimmed
update
	shark_attacks
set
	InvestigatorOrSource = trim(InvestigatorOrSource)
;


--------------------------------------------------------------------------------------------------------------------------------------------
/*
pdf Column

*/

select
	pdf
from
	shark_attacks
;
--This column is unnecessary for data analysis so it will be deleted
alter table
	shark_attacks
drop column
	pdf
;

-------------------------------------------------------------------------------------------------------------------------------------------
/*
hrefFormula and href Columns

These two columns look similar so they will be compared to determine if they are redundant.

*/

select
	hrefFormula
	, href
from
	shark_attacks
where
	hrefFormula <> href
;
--These two columns are nearly identical. Regardless, the information in them are not useful for data analysis so they will be deleted
alter table
	shark_attacks
drop column
	hrefFormula
	, href
;

-------------------------------------------------------------------------------------------------------------------------------------------
/*
OriginalOrder Column

It is unclear what this column is describing.

*/

select
	CaseNumber
	, OriginalOrder
from
	shark_attacks
order by
	OriginalOrder
;
--It looks like this column is organized by incident occurance and could possibly act as a primary key. To confirm, the records will be 
--checked to make sure each OriginalOrder is a unique value.
select
	OriginalOrder
	, count(*) as count
from
	shark_attacks
group by
	OriginalOrder
having
	count(*) > 1
;
--There are two null values and two records sharing the OriginalOrder value 569

--Start by checking the null values
select
	*
from
	shark_attacks
where
	OriginalOrder is null
;
--These records are almost entirely NULL with no usefull information, so these will be deleted from the table
delete from
	shark_attacks
where
	OriginalOrder is null
;

--Check the records sharing the OriginalOrder 569
select
	*
from
	shark_attacks
where
	OriginalOrder = 569
;
--Since this is the only duplicated value and these incidents occured only about a month apart, it may be assumed that this was a typo.

--Rather than attempting to reassign one value, which would affect the OriginalOrder of every incident reported after it, a new column
--will be created to renumber the records. This will also correct the numbering gaps caused by deleting the unnecessary records.
alter table
	shark_attacks
add
	IncidentNumber int
;

-- The OriginalOrder and CaseNumber will be used to number the records in the correct order
with new_column as(
select
	*
	, row_number() over (order by OriginalOrder, CaseNumber) as Number
from
	shark_attacks
)
update
	new_column
set
	IncidentNumber = Number
;

--Now the IncidentNumber column can be used as the primary key and the OriginalOrder column can be deleted.
alter table
	shark_attacks
alter column
	IncidentNumber int not null
;

alter table
	shark_attacks
add primary key
	(IncidentNumber)
;

alter table
	shark_attacks
drop column
	OriginalOrder
;

-------------------------------------------------------------------------------------------------------------------------------------------
/*
Duplication Check

*/
--Already set up but hasn't been run yet. Do this last and double check that all columns are included in the partiton (except pk)
with dupe_check as(
select
	*
	, row_number() over(partition by 
							CaseNumber
							, Date
							, Year
							, Type
							, Country
							, Area
							, Location
							, Activity
							, Name
							, Sex
							, Age
							, Injury
							, Fatal
							, Time
							, SharkDescription
							, InvestigatorOrSource
							, BodyPartInjured
							, SpeciesIdentified
						order by
							IncidentNumber
						) as dupe_number
from
	shark_attacks
)
select
	*
from
	dupe_check
where
	dupe_number > 1
;
--No duplicates found