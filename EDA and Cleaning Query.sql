-------------------------------------------------------------------------------------------------------------------------------

-- Looking at all the data

SELECT *
FROM [Project Portfolio Solo].[dbo].[Human Resources] order by id
-------------------------------------------------------------------------------------------------------------------------------

-- CLEANING PROCESS: create a copy table to ensure the raw data is unaltered ..

SELECT *
INTO [Cleaning Human Resources]
FROM [Project Portfolio Solo].[dbo].[Human Resources]

-------------------------------------------------------------------------------------------------------------------------------

-- Finding the redundant records: records with all columns null or records with all columns but one as null
SELECT * 
FROM [Cleaning Human Resources]
WHERE [id] is null
      and [first_name] is null
      and [last_name] is null
      and [birthdate] is null
      and [gender] is null
      and [race] is null
      and [department] is null
      --and[jobtitle]
      and [location] is null
      and [hire_date]  is null
      and [termdate] is null
      and [location_city] is null
      and [location_state] is null

 -- Deleting the redundant records: all columns are null & all columns but one are null
DELETE  
FROM [Cleaning Human Resources]
WHERE [id] is null
      and [first_name] is null
      and [last_name] is null
      and [birthdate] is null
      and [gender] is null
      and [race] is null
      and [department] is null
      --and[jobtitle]
      and [location] is null
      and [hire_date]  is null
      and [termdate] is null
      and [location_city] is null
      and [location_state] is null

-------------------------------------------------------------------------------------------------------------------------------

-- CHANGING DATE DATATYPE: columns with dates ... birthdate & hiredate; termdate is useless metric (drop column)

SELECT birthdate, CONVERT(DATE,birthdate) birthdate_clean, hire_date, CONVERT(DATE,hire_date)FROM [Cleaning Human Resources]

   -- safest way: add columns to table, then drop previous columns; as oppose to directly altering and modifying? 
ALTER TABLE [Cleaning Human Resources]
add birthdate_clean date

update [Cleaning Human Resources]
set birthdate_clean = CONVERT(DATE,birthdate)


ALTER TABLE [Cleaning Human Resources]
add hiredate_clean date

update [Cleaning Human Resources]
set hiredate_clean = CONVERT(DATE,hire_date)

SELECT * FROM [Cleaning Human Resources]

ALTER TABLE [Cleaning Human Resources]
DROP COLUMN birthdate, hire_date, termdate

-------------------------------------------------------------------------------------------------------------------------------

-- duplicated data?

--1st check: Unique identifier column "Primary Key" 
SELECT count(*), count(distinct id) from [Cleaning Human Resources]

--2nd check: Picking attributes which likely would be unique 
SELECT first_name, last_name, birthdate_clean FROM [Cleaning Human Resources] GROUP BY first_name, last_name, birthdate_clean HAVING count(*) > 1

-------------------------------------------------------------------------------------------------------------------------------
---------
-- EDA --
---------

-- Looking at proportions and potential groupings. 
SELECT distinct gender FROM [Cleaning Human Resources]
SELECT distinct race FROM [Cleaning Human Resources]
SELECT distinct department FROM [Cleaning Human Resources]
SELECT distinct jobtitle FROM [Cleaning Human Resources] 
SELECT distinct location FROM [Cleaning Human Resources] 
SELECT distinct location_city FROM [Cleaning Human Resources] 
SELECT distinct location_state FROM [Cleaning Human Resources] 


-- Using time metrics: 1) view by age 2) can't do time series 

-- AGE OF EMPLOYEES (creating buckets)

with AgeGrouping as (
SELECT *, DATEDIFF(YEAR, birthdate_clean, CONVERT(date,GETDATE())) Agex,
	CASE 
		WHEN DATEDIFF(YEAR, birthdate_clean, CONVERT(date,GETDATE())) BETWEEN 20 AND 29 THEN '20 - 29'
		WHEN DATEDIFF(YEAR, birthdate_clean, CONVERT(date,GETDATE())) BETWEEN 30 AND 39 THEN '30 - 39'
		WHEN DATEDIFF(YEAR, birthdate_clean, CONVERT(date,GETDATE())) BETWEEN 40 AND 49 THEN '40 - 49'
		WHEN DATEDIFF(YEAR, birthdate_clean, CONVERT(date,GETDATE())) >= 50 THEN '50+'
		ELSE 'Logic Error'
		END as [Age_Group]
FROM [Cleaning Human Resources]
					)
SELECT Age_Group, count(*) count FROM AgeGrouping GROUP BY [Age_Group] ORDER BY 2;

-------------------------------------------------------------------------------------------------------------------------------

-- High Level view of employees [Tableau]
SELECT location_state, count(*) FROM [Cleaning Human Resources] GROUP BY location_state

-- mid Level view of employees by gender [Tableau]
SELECT location_state, gender , count(*) count FROM [Cleaning Human Resources] GROUP BY location_state, gender ORDER BY 1,2

-- low Level view of employees by gender by department by state [Tableau]
SELECT location_state, gender, department, count(*) num_of FROM [Cleaning Human Resources] GROUP BY location_state, gender, department order by 1,3



--- Proportions on low level view
with CTE1 as (
SELECT location_state, gender, count(*) num_of FROM [Cleaning Human Resources] GROUP BY location_state, gender
			 ),
	CTE2 as (
SELECT location_state, gender, num_of, 
		SUM(num_of)
		OVER (PARTITION BY location_state) department_total_employees
FROM CTE1
			)
SELECT 
	Location_state,
	gender, 
	num_of as count,
	cast(num_of as numeric)/department_total_employees*100 proportion
FROM CTE2
;

-- Pivoting results for readability 
with CTE1 as (
SELECT location_state, gender, count(*) num_of FROM [Cleaning Human Resources] GROUP BY location_state, gender
			 ),
	CTE2 as (
SELECT location_state, gender, num_of, 
		SUM(num_of)
		OVER (PARTITION BY location_state) department_total_employees
FROM CTE1
			),
	CTE3 as (
SELECT 
	Location_state,
	gender, 
	num_of as count,
	cast(num_of as numeric)/department_total_employees*100 proportion
FROM CTE2
)
SELECT location_state, 
	sum(CASE WHEN gender = 'Male' then count else NULL END) AS Male,
	sum(CASE WHEN gender = 'Female' then count else NULL END) AS Female,
	sum(CASE WHEN gender = 'Non-Conforming' then count else NULL END) AS [Non-Conforming]
FROM CTE3 
GROUP BY location_state;



--- By state; gender split across the departments. [tableau] (gender distribution by department [multi bar])
with CTE1 as (
SELECT location_state, gender, department, count(*) num_of FROM [Cleaning Human Resources] GROUP BY location_state, gender, department
			 ),
	CTE2 as (
SELECT location_state, gender, department, num_of, 
		SUM(num_of)
		OVER (PARTITION BY location_state,department) department_total_employees
FROM CTE1
			)
SELECT 
	Location_state,
	gender, 
	department, 
	num_of as count,
	cast(num_of as numeric)/department_total_employees*100 proportion
FROM CTE2;


----------------------------------------------------------------------------------------------------------------

-- Summary; looking at the HR data, in Tableau I will show employees by state, and then within the states: employees gender distribution and department distribution 

-- employees in each state
SELECT location_state, count(*) employees FROM [Cleaning Human Resources] GROUP BY location_state

-- employees in each department
SELECT department , count(*) employees  FROM [Cleaning Human Resources] GROUP BY location_state, department ORDER BY 1 

-- by state, employees in each department 
SELECT department, location_state, count(*) num_of_employees  FROM [Cleaning Human Resources] GROUP BY department, location_state ORDER BY 1,3

--- By state; gender split across the departments. 
with CTE1 as (
SELECT location_state, gender, department, count(*) num_of FROM [Cleaning Human Resources] GROUP BY location_state, gender, department
			 ),
	CTE2 as (
SELECT location_state, gender, department, num_of, 
		SUM(num_of)
		OVER (PARTITION BY location_state,department) department_total_employees
FROM CTE1
			)
SELECT 
	Location_state,
	gender, 
	department, 
	num_of as count,
	cast(num_of as numeric)/department_total_employees*100 proportion
FROM CTE2;

/*  
	Could still look at: 
1. age distribution
2. race distrubution
3. popular jobtitles (even partial words using like operator)
4. location (HQ vs Remote) .. 
5. using city data 

*/

