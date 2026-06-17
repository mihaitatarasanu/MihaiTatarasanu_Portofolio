#Automated Data Cleaning Project


/*This project demonstrates how the US Household Income dataset can be cleaned through an automated MySQL workflow. By automating the data cleaning process, the dataset can be consistently prepared for analysis with minimal manual intervention.*/


SELECT * 
FROM us_household_income.us_household_income2
;

SELECT * 
FROM us_household_income.us_household_income2_cleaned;


/*Before we jump into work, let's create a copy of the 'us_household_income.us_household_income2' table. We now have a backup just in case. We must add a 'TimeStamp' column because we are creating an automated process, and if there is an error after a while of running, it will help us understand what change has happened at a specific date.*/
/*CREATE TABLE `us_household_income2_Cleaned` (
  `row_id` int DEFAULT NULL,
  `id` int DEFAULT NULL,
  `State_Code` int DEFAULT NULL,
  `State_Name` text,
  `State_ab` text,
  `County` text,
  `City` text,
  `Place` text,
  `Type` text,
  `Primary` text,
  `Zip_Code` int DEFAULT NULL,
  `Area_Code` int DEFAULT NULL,
  `ALand` int DEFAULT NULL,
  `AWater` int DEFAULT NULL,
  `Lat` double DEFAULT NULL,
  `Lon` double DEFAULT NULL,
  `TimeStamp` TIMESTAMP DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;*/

/*The following steps walk through the creation of a MySQL stored procedure that automates the data cleaning process. The procedure creates a new table, loads the dataset, and applies each cleaning operation in sequence, resulting in a clean and standardized dataset.*/

DELIMITER $$
DROP PROCEDURE IF EXISTS Copy_and_Clean_Data;
CREATE PROCEDURE Copy_and_Clean_Data()
BEGIN
-- Creating our table
	CREATE TABLE IF NOT EXISTS `us_household_income2_Cleaned` (
	  `row_id` int DEFAULT NULL,
	  `id` int DEFAULT NULL,
	  `State_Code` int DEFAULT NULL,
	  `State_Name` text,
	  `State_ab` text,
	  `County` text,
	  `City` text,
	  `Place` text,
	  `Type` text,
	  `Primary` text,
	  `Zip_Code` int DEFAULT NULL,
	  `Area_Code` int DEFAULT NULL,
	  `ALand` int DEFAULT NULL,
	  `AWater` int DEFAULT NULL,
	  `Lat` double DEFAULT NULL,
	  `Lon` double DEFAULT NULL,
	  `TimeStamp` TIMESTAMP DEFAULT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- We copy the data to the new table
		INSERT INTO us_household_income2_Cleaned
		SELECT *, CURRENT_TIMESTAMP 
		FROM us_household_income.us_household_income2;

-- Data cleaning steps
-- 1.Remove Duplicates
		DELETE FROM us_household_income2_Cleaned 
		WHERE 
			row_id IN (
			SELECT row_id
		FROM (
			SELECT row_id, id,
				ROW_NUMBER() OVER (
                /*The "TimeStamp" makes a row unique. If we use the 'id' alone, every time we run it on a specified schedule the id column will have duplicates, and it becomes an issue for our automation.*/
					PARTITION BY id, `TimeStamp`
					ORDER BY id, `TimeStamp`) AS row_num
			FROM 
				us_household_income2_Cleaned
		) duplicates
		WHERE 
			row_num > 1
		);
-- 2.Standardization
-- Fixing some data quality issues by fixing typos and general standardization
		UPDATE us_household_income2_Cleaned
		SET State_Name = 'Georgia'
		WHERE State_Name = 'georia';

		UPDATE us_household_income2_Cleaned
		SET County = UPPER(County);

		UPDATE us_household_income2_Cleaned
		SET City = UPPER(City);

		UPDATE us_household_income2_Cleaned
		SET Place = UPPER(Place);

		UPDATE us_household_income2_Cleaned
		SET State_Name = UPPER(State_Name);

		UPDATE us_household_income2_Cleaned
		SET `Type` = 'CDP'
		WHERE `Type` = 'CPD';

		UPDATE us_household_income2_Cleaned
		SET `Type` = 'Borough'
		WHERE `Type` = 'Boroughs';
        
END $$
DELIMITER ;


CALL Copy_and_Clean_Data();


-- Let's create an event that calls the procedure we just created every 2 minutes

CREATE EVENT run_data_cleaning
	ON Schedule EVERY 2 MINUTE
    DO CALL Copy_and_Clean_Data();


/*The same data is added every 2 minutes, with a new timestamp generated each time by the 'run_data_cleaning' event.*/

SELECT * FROM us_household_income.us_household_income2_cleaned;

SELECT DISTINCT TimeStamp FROM us_household_income.us_household_income2_cleaned;


-- Changed the schedule because the result set was increasing in size every 2 minutes.

DROP EVENT run_data_cleaning;
CREATE EVENT run_data_cleaning
	ON Schedule EVERY 30 DAY
    DO CALL Copy_and_Clean_Data();


/*Let's delete the "us_household_income2_Cleaned" table. 
The results below are the results before the data cleaning.*/

-- We are looking for the duplicates.

			SELECT row_id, id, row_num
		FROM (
			SELECT row_id, id,
				ROW_NUMBER() OVER (
					PARTITION BY id
					ORDER BY id) AS row_num
			FROM 
				us_household_income2
		) duplicates
		WHERE 
			row_num > 1;


-- Let's count how many rows we have.

SELECT COUNT(row_id)
FROM us_household_income2;


/*These are the state names that need to be fixed.(Georgia, georia), The count number of Georgia it's going to change after standardization.*/

SELECT State_Name, COUNT(State_Name)
FROM us_household_income2
GROUP BY State_Name;


-- We run our stored procedure again.

CALL Copy_and_Clean_Data();


/* The results below are the results after the data cleaning. The duplicates were removed, there are fewer row_id values, and the state names are fixed.*/

			SELECT row_id, id, row_num
		FROM (
			SELECT row_id, id,
				ROW_NUMBER() OVER (
					PARTITION BY id
					ORDER BY id) AS row_num
			FROM 
				us_household_income2_Cleaned
		) duplicates
		WHERE 
			row_num > 1;


SELECT COUNT(row_id)
FROM us_household_income2_Cleaned;


SELECT State_Name, COUNT(State_Name)
FROM us_household_income2_Cleaned
GROUP BY State_Name;







