#World Life Expectancy Project 


/*This project demonstrates the process of cleaning the World Life Expectancy dataset, followed by exploratory data analysis to identify trends and patterns within the data.*/


-- Data Cleaning


SELECT * 
FROM world_life_expectancy
;


/*First of all we are going to remove duplicates. In order to find which rows are duplicates we are going to concatenate the "country" column with the "year" column, because as a whole there should be one of each if there are no duplicates.*/

SELECT Country, Year, CONCAT(Country, Year), /*Now we are going to count how many times each concatenation appears.*/ COUNT(CONCAT(Country, Year))
FROM world_life_expectancy
GROUP BY Country, Year, CONCAT(Country, Year)
/*We need the records that have a count bigger than 1. This shows us how many duplicates we have.*/
HAVING COUNT(CONCAT(Country, Year)) > 1
;


/*Now that we have identified that there are duplicates, we will use the "Row_ID" column to see which columns are the duplicates in order to remove them*/

SELECT * 
FROM (
	SELECT Row_ID, 
	CONCAT(Country, Year),
	ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_Num
	FROM world_life_expectancy
    ) AS Row_table
/*Now, every row that has a number bigger than 1 is a duplicate, so we know what to delete.*/
WHERE Row_Num > 1
;


/*Before everything we are going to create a Backup for our table before we start to delete the duplicates. */

DELETE FROM world_life_expectancy
WHERE  
	/*We are using what we just tested as a subquery in order to delete all the duplicates. */
	Row_ID IN (
    SELECT Row_ID 
FROM (
	SELECT Row_ID, 
	CONCAT(Country, Year),
	ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_Num
	FROM world_life_expectancy
    ) AS Row_table
WHERE Row_Num > 1
)
;
	

/*Let's see which rows have a blank status.*/

SELECT * 
FROM world_life_expectancy
WHERE Status = ''
;


/*Let's see all the distinct records within the "Status" column.*/

SELECT DISTINCT Status
FROM world_life_expectancy
WHERE Status <> ''
;

SELECT DISTINCT Country
FROM world_life_expectancy
WHERE Status ='developing'
;


/*We are going to update the blank values within the "Status" column with 'developing' if the value in the "country" column matches a specific country value that has 'developing' assigned to it.*/

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status= ''
AND t2.Status <> ''
AND t2.Status = 'Developing'
;


/*There is one row left in the "Status" column with a blank value.*/

SELECT * 
FROM world_life_expectancy
WHERE Status = ''
;


/*This blank value was not updated because the status is "Developed" instead of "Developing".*/

SELECT * 
FROM world_life_expectancy
WHERE Country = 'United States of America'
;


/*We are going to update the blank values within the "Status" column with 'developed' if the value in the "country" column matches a specific country value that has 'developed' assigned to it.*/

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status= ''
AND t2.Status <> ''
AND t2.Status = 'Developed'
;


/*We can see that it has been populated properly.*/

SELECT * 
FROM world_life_expectancy
WHERE Country = 'United States of America'
;


/*Let's see the rows that have the "Life expectancy" column blank.*/

SELECT * 
FROM world_life_expectancy
WHERE `Life expectancy` = ''
;

SELECT * 
FROM world_life_expectancy
;


/*We can see that the life expectancy for each country is slowly increasing. We can populate the blank value in the "Life expectancy" column, let's say for year x, with the average of the values assigned to years x−1 and x+1 using a self-join.*/

SELECT t1.Country, t1.Year, t1.`Life expectancy`, 
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`,
ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.year + 1
WHERE t1.`Life expectancy` = ''
;


/*Now let's update the blank values with everything we have worked on above.*/

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.year + 1
SET t1.`Life expectancy`= ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
WHERE t1.`Life expectancy`=''
;


/*We can see that there are no more rows that have a `Life expectancy` blank value*/

SELECT * 
FROM world_life_expectancy
WHERE `Life expectancy` = ''
;




-- Exploratory Data Analysis
/*With the dataset cleaned and normalized, we can now perform exploratory data analysis to identify patterns, relationships, and insights within the World Life Expectancy dataset.*/


SELECT * 
FROM world_life_expectancy
;


/*How have countries done in the past 15 years in terms of life expectancy?
From the analysis, we can see that the majority of countries experienced a steady increase in life expectancy over the past 15 years.*/

SELECT Country, MIN(`Life expectancy`), MAX(`Life expectancy`)
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY Country DESC
;


/*Which countries have made the biggest strides in life expectancy?
The results indicate that countries with the lowest initial life expectancy saw substantial gains throughout the 15-year period.*/

SELECT Country, 
MIN(`Life expectancy`), 
MAX(`Life expectancy`),
ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`),1) AS Life_increase_15_years
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY Life_increase_15_years DESC
;


/*What is the average life expectancy for each year?
Average life expectancy exhibits a gradual upward trend, increasing steadily each year.*/

SELECT Year, ROUND(AVG(`Life expectancy`),2)
FROM world_life_expectancy
WHERE `Life expectancy` <> 0
AND `Life expectancy` <> 0
GROUP BY Year
ORDER BY Year
;


/*What is the correlation between life expectancy and GDP? Does life expectancy increase if countries make more money?
The analysis demonstrates a positive correlation between GDP and life expectancy. While GDP is not the only factor influencing life expectancy, countries with stronger economies generally exhibit higher average life expectancy.*/

SELECT Country, ROUND(AVG(`Life expectancy`),1) AS Life_exp, ROUND(AVG(GDP),1) as GDP
FROM world_life_expectancy
GROUP BY Country
HAVING Life_exp > 0
AND GDP > 0
ORDER BY GDP ASC
;


/*How many countries have a GDP higher than 1500? When the average GDP is higher than 1500, let's see the life expectancy. Let's compare it with the countries that have a GDP lower than 1500.

Countries with higher GDP generally exhibit higher life expectancy values. However, the number of countries in the higher GDP category is smaller, so this distribution should be considered when interpreting the results.*/

SELECT 
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) High_gdp_count,
AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE NULL END) High_gdp_Life_expectancy,
SUM(CASE WHEN GDP <= 1500 THEN 1 ELSE 0 END) High_gdp_count,
AVG(CASE WHEN GDP <= 1500 THEN `Life expectancy` ELSE NULL END) High_gdp_Life_expectancy
FROM world_life_expectancy
;


/*What is the average life expectancy between the two status values?*/

SELECT Status, ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy
GROUP BY Status
;


/*Let's see how many countries are involved in this scenario.

The analysis shows that developed countries have a higher average GDP. However, before drawing conclusions, it's important to examine how many countries belong to each development status, as the sample sizes may influence the results.*/

SELECT Status, COUNT(DISTINCT Country), ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy
GROUP BY Status
;


/*What will the average BMI be for each country? Let’s also compare it to the average life expectancy.
The results show that several countries with the highest average BMI also have relatively high life expectancy. However, there are notable exceptions, suggesting that while BMI is associated with life expectancy, it is not the sole factor influencing it.*/

SELECT Country, ROUND(AVG(`Life expectancy`),1) AS Life_exp, ROUND(AVG(BMI),1) as BMI
FROM world_life_expectancy
GROUP BY Country
HAVING Life_exp > 0
AND BMI > 0
ORDER BY BMI DESC
;


/*How many people are dying each year in a country, and is it a lot compared to the life expectancy value?
The analysis shows an inverse relationship between life expectancy and mortality. As life expectancy increases, the number of deaths generally decreases.*/

SELECT Country, Year,
`Life expectancy`,
`Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Total
FROM world_life_expectancy
;






