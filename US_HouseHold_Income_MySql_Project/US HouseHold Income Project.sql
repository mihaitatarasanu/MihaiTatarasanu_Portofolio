#US Household Income Project 


/*This project demonstrates the process of cleaning the US Household Income dataset, followed by exploratory data analysis to identify trends and patterns within the data.*/


-- Data Cleaning



SELECT * 
FROM us_project.us_household_income;

SELECT * 
FROM us_project.us_household_income_statistics;


/*While looking at the "us_project.us_household_income_statistics" table, we see that the name of the first column is altered, so we are going to rename it as "ID".*/

ALTER TABLE us_project.us_household_income_statistics
RENAME COLUMN `ï»¿id` TO `id`;


/*Let's compare the number of rows in the two tables to understand if there are missing rows.
It is revealed that there is a small number of missing records. Given the limited discrepancy, the impact on the analysis is expected to be negligible.*/

SELECT COUNT(id)
FROM us_project.us_household_income;

SELECT COUNT(id)
FROM us_project.us_household_income_statistics;


/*First of all, we are going to remove duplicates. We are using the "id" column to investigate how many times each "id" is repeated. If it repeats more than one time, it means that that specific id has duplicates.*/

SELECT id, COUNT(id)
FROM us_project.us_household_income
GROUP BY id
HAVING COUNT(id) >1
;
 
 
/*Now that we have identified that there are duplicates, we will use the "row_ID" column to see which rows are duplicates in order to remove them.*/

SELECT *
FROM (
SELECT row_id, 
id,
ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) row_num
FROM us_project.us_household_income
) duplicates
/*Every row that has a number bigger than 1 is going to be a duplicate.*/
WHERE row_num > 1
;


/*Before everything, we are going to create a backup of our table before we start deleting the duplicates. */


DELETE FROM us_project.us_household_income
/*We are using what we just tested as a subquery in order to delete all the duplicates.*/
WHERE row_id IN (
	SELECT row_id
	FROM (
		SELECT row_id, 
		id,
		ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) row_num
		FROM us_project.us_household_income
		) duplicates
WHERE row_num > 1)
;


/*We investigate how many duplicates we have for the second table using the same method. There are none.*/

SELECT id, COUNT(id)
FROM us_project.us_household_income_statistics
GROUP BY id
HAVING COUNT(id) >1
;


/*We are going to check if there are spelling mistakes for each country in the "us_project.us_household_income" table by counting how many times each country appears in the State_name column. For example, Georgia appears both as "georia" and "Georgia".*/

SELECT State_Name, COUNT(State_Name) 
FROM us_project.us_household_income
GROUP BY State_Name
;


/*We are updating the 'georia' values within the State_Name column with the value 'Georgia'.*/

UPDATE us_project.us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia'
;


/*Even though "Georgia" had the only spelling mistake in the query we ran above, in the "us_project.us_household_income" table Alabama appears both as "Alabama" and "alabama". So we are going to fix it too.*/

UPDATE us_project.us_household_income
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama'
;


/*Let's see if row_id = 32 is the only row that has the 'Place' column blank.*/

SELECT *
FROM us_project.us_household_income
WHERE Place = ''
;


/*We want to investigate whether every value within the 'Place' column is the same. It is almost the case, since only one row doesn't follow this pattern, so we can populate the blank value with 'Autaugaville'.*/

SELECT *
FROM us_project.us_household_income
WHERE County = 'Autauga County'
;


UPDATE us_project.us_household_income
SET Place = 'Autaugaville'
WHERE County = 'Autauga County'
AND City = 'Vinemont'
;


/*We are going to test for spelling mistakes in the 'Type' column.*/

SELECT Type, COUNT(Type)
FROM us_project.us_household_income
GROUP BY Type
;


/*It seems like "Boroughs" is also spelled "Borough", so we are going to fix it. We also have "CDP" and "CPD", but they might be two different things.*/

UPDATE us_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs'
;


/*Let's investigate whether in the "AWater" column we also find the values 0, null, or blank.*/

SELECT ALand, AWater
FROM us_project.us_household_income
WHERE AWater = 0 OR AWater = '' OR AWater IS NULL
;


/*Are all of the records from the above query within the 'AWater' column 0? The answer is yes.*/

SELECT DISTINCT AWater
FROM us_project.us_household_income
WHERE AWater = 0 OR AWater = '' OR AWater IS NULL
;


/*Let's investigate whether in the ALand column we also find the values 0, null, or blank.*/

SELECT ALand, AWater
FROM us_project.us_household_income
WHERE ALand = 0 OR ALand = '' OR ALand IS NULL
;


/*Do we find rows using these columns that contain on both sides only the values 0, null, or blank? The answer is no.*/

SELECT ALand, AWater
FROM us_project.us_household_income
WHERE 
(AWater = 0 OR AWater = '' OR AWater IS NULL)
AND (ALand = 0 OR ALand = '' OR ALand IS NULL)
;




-- Exploratory Data Analysis
/*After preparing the dataset, the next step is exploratory data analysis (EDA), where we examine key metrics, identify trends, and explore relationships between variables.*/

SELECT * 
FROM us_project.us_household_income
;

SELECT * 
FROM us_project.us_household_income_statistics
;


/*Which state has the largest land area?*/

SELECT State_Name, SUM(ALand), SUM(AWater) 
FROM us_project.us_household_income
GROUP BY State_Name
ORDER BY 2 DESC
;


/*Which state has the largest water area?*/

SELECT State_Name, SUM(ALand), SUM(AWater) 
FROM us_project.us_household_income
GROUP BY State_Name
ORDER BY 3 DESC
;


/*Let's identify the top 10 largest States by land*/

SELECT State_Name, SUM(ALand), SUM(AWater) 
FROM us_project.us_household_income
GROUP BY State_Name
ORDER BY 2 DESC
LIMIT 10
;


/*Let's identify the top 10 largest States by water*/
/*We understand that land area and water area are not directly proportional. States with the largest land area do not necessarily rank among those with the largest water area.*/

SELECT State_Name, SUM(ALand), SUM(AWater) 
FROM us_project.us_household_income
GROUP BY State_Name
ORDER BY 3 DESC
limit 10
;


/*Let's bring all the records from the 'us_project.us_household_income_statistics' table whose 'id' does not match any values in the 'id' column from the 'us_project.us_household_income' table. This is the data we are missing in the 'us_household_income_statistics'.*/

SELECT * 
FROM us_project.us_household_income u
RIGHT JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE u.id IS NULL
;


/*Going through the inner join of the two tables, we realize that there are rows with the value 0 in the last four columns. Let's filter the inner join to exclude them. Now we have much cleaner data.*/

SELECT * 
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
;


/*Let's bring together more of our categorical data from both tables.*/

SELECT u.State_Name, County, Type, `Primary`, Mean, Median
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
;


/*What is the average Mean and Median for each state?
By comparing average mean and median income, we gain a more complete picture of household income across states. While the mean reflects the overall average, the median represents the typical household income and is less influenced by extreme values, making it an important measure when evaluating income distribution.*/

SELECT u.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 2
;


/*Let's return the bottom 5 states with the lowest average mean income values.
When the mean income is higher than the median income, it typically indicates that a relatively small number of very high-income values are pulling the average upward. In this case, the income distribution is right-skewed.
Conversely, when the mean income is lower than the median income, it suggests that relatively low-income values are pulling the average downward, resulting in a left-skewed distribution.*/

SELECT u.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 2
LIMIT 5
;


/*Let's return the top 5 states with the highest average mean income values.*/

SELECT u.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 2 DESC
LIMIT 5
;


/*Let's see what the average mean is from highest to lowest for each value within the "Type" column.*/ 

SELECT Type, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY TYPE
ORDER BY 2 DESC
LIMIT 10
;


/*Since Municipality has the highest average value, it's important to examine the number of records for each location type. The results show that only one Municipality is included in the dataset, making its average less reliable than those calculated from larger sample sizes.*/

SELECT Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY TYPE
ORDER BY 2 DESC
;


/*What are the highest average median incomes for each 'Type' value? The 'Community' type is at the bottom, so let's see which states have this 'Community' type.
Puerto Rico stands out from the other entries due to its significantly lower income levels. As a U.S. territory rather than a state, its economic conditions differ substantially from those of the 50 states, which should be considered when interpreting the results.*/

SELECT Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY TYPE
ORDER BY 3 DESC
;

SELECT *
FROM us_project.us_household_income
WHERE Type = 'Community'
;


/*Let's keep only the types with a higher count, since they give us better statistics.*/

SELECT Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY TYPE
HAVING COUNT(TYPE) > 100
ORDER BY 3 DESC
;


/*What do salaries look like in the bigger cities?
The analysis shows that many of the highest-income locations are affluent suburban communities rather than large metropolitan cities. Many are situated near major economic hubs such as New York City, Washington, D.C., San Francisco, Los Angeles, and Chicago, suggesting that proximity to these urban centers is associated with higher household incomes.*/

SELECT u.State_Name, City, ROUND(AVG(Mean),1) 
FROM us_project.us_household_income u
RIGHT JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
GROUP BY u.State_Name, City
ORDER BY ROUND(AVG(Mean),1) DESC
;


/*Let's add the average median income. We can observe that the value 300,000 repeats often. It might be just a cap placed there.*/

SELECT u.State_Name, City, ROUND(AVG(Mean),1) , ROUND(AVG(Median),1)
FROM us_project.us_household_income u
RIGHT JOIN us_project.us_household_income_statistics us
	ON u.id = us.id
GROUP BY u.State_Name, City
ORDER BY ROUND(AVG(Mean),1) DESC
;
