create database Restaurant;

use Restaurant;

ALTER TABLE consumer_preferences
ADD CONSTRAINT fk_cp_consumer
FOREIGN KEY (Consumer_ID)
REFERENCES consumers(Consumer_ID)
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE restaurant_cuisines
ADD CONSTRAINT fk_rc_restaurant
FOREIGN KEY (Restaurant_ID)
REFERENCES restaurants(Restaurant_ID)
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE ratings
ADD CONSTRAINT fk_ratings_consumer
FOREIGN KEY (Consumer_ID)
REFERENCES consumers(Consumer_ID)
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE ratings
ADD CONSTRAINT fk_ratings_restaurant
FOREIGN KEY (Restaurant_ID)
REFERENCES restaurants(Restaurant_ID)
ON DELETE CASCADE ON UPDATE CASCADE;

# Objective: 

-- Using the WHERE clause to filter data based on specific criteria.
--  1. List all details of consumers who live in the city of 'Cuernavaca'.

SELECT *
FROM consumers
WHERE City = 'Cuernavaca';


-- 2. Students who are smokers

SELECT Consumer_ID, Age, Occupation
FROM consumers
WHERE Occupation = 'Student' AND Smoker = 'Yes';

-- 3. Restaurants with Wine & Beer + Medium price

SELECT Name, City, Alcohol_Service, Price
FROM restaurants
WHERE Alcohol_Service = 'Wine & Beer'
  AND Price = 'Medium';
  
-- 4. Restaurants that are Franchise

SELECT Name, City
FROM restaurants
WHERE Franchise = 'Yes'; 

-- 5. Ratings where Overall_Rating = 2

SELECT Consumer_ID, Restaurant_ID, Overall_Rating
FROM ratings
WHERE Overall_Rating = 2;


# Questions JOINs with Subqueries
-- 1. Restaurants that got rating 2

SELECT DISTINCT r.Name, r.City
FROM restaurants r
JOIN ratings rt ON r.Restaurant_ID = rt.Restaurant_ID
WHERE rt.Overall_Rating = 2;

-- 2. Consumers who rated restaurants in San Luis Potosi
SELECT DISTINCT c.Consumer_ID, c.Age
FROM consumers c
JOIN ratings rt ON c.Consumer_ID = rt.Consumer_ID
JOIN restaurants r ON rt.Restaurant_ID = r.Restaurant_ID
WHERE r.City = 'San Luis Potosi';

-- 3. Mexican restaurants rated by U1001
SELECT DISTINCT r.Name
FROM restaurants r
JOIN restaurant_cuisines rc ON r.Restaurant_ID = rc.Restaurant_ID
JOIN ratings rt ON r.Restaurant_ID = rt.Restaurant_ID
WHERE rc.Cuisine = 'Mexican'
  AND rt.Consumer_ID = 'U1001';

-- 4. Consumers who prefer American and have Medium budget
SELECT DISTINCT c.*
FROM consumers c
JOIN consumer_preferences cp ON c.Consumer_ID = cp.Consumer_ID
WHERE cp.Preferred_Cuisine = 'American'
  AND c.Budget = 'Medium';

-- 5. Restaurants with Food rating < average

SELECT r.Name, r.City
FROM restaurants r
JOIN ratings rt ON r.Restaurant_ID = rt.Restaurant_ID
GROUP BY r.Restaurant_ID
HAVING AVG(rt.Food_Rating) < (SELECT AVG(Food_Rating) FROM ratings);

-- 6. Consumers who rated but NOT Italian restaurants
SELECT DISTINCT c.Consumer_ID, c.Age, c.Occupation
FROM consumers c
WHERE EXISTS (
    SELECT 1 FROM ratings rt WHERE rt.Consumer_ID = c.Consumer_ID
)
AND NOT EXISTS (
    SELECT 1
    FROM ratings rt
    JOIN restaurant_cuisines rc ON rt.Restaurant_ID = rc.Restaurant_ID
    WHERE rt.Consumer_ID = c.Consumer_ID
      AND rc.Cuisine = 'Italian'
);

-- 7. Restaurants rated by people older than 30
SELECT DISTINCT r.Name
FROM restaurants r
JOIN ratings rt ON r.Restaurant_ID = rt.Restaurant_ID
JOIN consumers c ON rt.Consumer_ID = c.Consumer_ID
WHERE c.Age > 30;

-- 8. Consumers who like Mexican & rated something with overall 0
SELECT DISTINCT c.Consumer_ID, c.Occupation
FROM consumers c
JOIN consumer_preferences cp ON c.Consumer_ID = cp.Consumer_ID
WHERE cp.Preferred_Cuisine = 'Mexican'
  AND EXISTS (
      SELECT 1 FROM ratings rt
      WHERE rt.Consumer_ID = c.Consumer_ID
        AND rt.Overall_Rating = 0
  );

-- 9. Pizzeria restaurants in cities with students
SELECT DISTINCT r.Name, r.City
FROM restaurants r
JOIN restaurant_cuisines rc ON r.Restaurant_ID = rc.Restaurant_ID
WHERE rc.Cuisine = 'Pizzeria'
  AND r.City IN (
      SELECT DISTINCT City FROM consumers
      WHERE Occupation = 'Student'
  );

-- 10. Social drinkers who rated restaurants with NO parking
SELECT DISTINCT c.Consumer_ID, c.Age
FROM consumers c
JOIN ratings rt ON c.Consumer_ID = rt.Consumer_ID
JOIN restaurants r ON rt.Restaurant_ID = r.Restaurant_ID
WHERE c.Drink_Level = 'Social Drinker'
  AND r.Parking = 'No';
  
# Questions Emphasizing WHERE Clause and Order of Execution
  
-- 1. Students who rated more than 2 restaurants
SELECT rt.Consumer_ID, COUNT(DISTINCT rt.Restaurant_ID) AS count_rated
FROM ratings rt
JOIN consumers c ON rt.Consumer_ID = c.Consumer_ID
WHERE c.Occupation = 'Student'
GROUP BY rt.Consumer_ID
HAVING COUNT(DISTINCT rt.Restaurant_ID) > 2;

-- 2. Engagement Score (Age/10 = 2)
SELECT Consumer_ID, Age, FLOOR(Age / 10) AS Engagement_Score
FROM consumers
WHERE FLOOR(Age / 10) = 2
  AND Transportation_Method = 'Public';

-- 3. Cuernavaca restaurants with avg rating > 1.0
SELECT r.Name, r.City, AVG(rt.Overall_Rating) AS avg_rating
FROM restaurants r
JOIN ratings rt ON r.Restaurant_ID = rt.Restaurant_ID
WHERE r.City = 'Cuernavaca'
GROUP BY r.Restaurant_ID
HAVING avg_rating > 1.0;

-- 4. Married consumers where Food = Service rating and Overall=2
SELECT DISTINCT c.Consumer_ID, c.Age
FROM consumers c
JOIN ratings rt ON c.Consumer_ID = rt.Consumer_ID
WHERE c.Marital_Status = 'Married'
  AND rt.Overall_Rating = 2
  AND rt.Food_Rating = rt.Service_Rating;

-- 5. Employed consumers who gave Food=0 to Ciudad Victoria restaurant
SELECT DISTINCT c.Consumer_ID, c.Age, r.Name
FROM consumers c
JOIN ratings rt ON c.Consumer_ID = rt.Consumer_ID
JOIN restaurants r ON rt.Restaurant_ID = r.Restaurant_ID
WHERE c.Occupation = 'Employed'
  AND rt.Food_Rating = 0
  AND r.City = 'Ciudad Victoria';
  
  
# Advanced SQL Concepts: Derived Tables, CTEs, Window Functions, Views, Stored Procedures

-- 1. CTE + Mexican restaurants rated 2
WITH cte AS (
    SELECT * FROM consumers WHERE City = 'San Luis Potosi'
)
SELECT DISTINCT cte.Consumer_ID, cte.Age, r.Name
FROM cte
JOIN ratings rt ON cte.Consumer_ID = rt.Consumer_ID
JOIN restaurants r ON rt.Restaurant_ID = r.Restaurant_ID
JOIN restaurant_cuisines rc ON r.Restaurant_ID = rc.Restaurant_ID
WHERE rc.Cuisine = 'Mexican'
  AND rt.Overall_Rating = 2;

-- 2. Average age by occupation (only consumers who rated)
WITH rated AS (
    SELECT DISTINCT Consumer_ID FROM ratings
)
SELECT c.Occupation, AVG(c.Age) AS avg_age
FROM consumers c
JOIN rated r ON c.Consumer_ID = r.Consumer_ID
GROUP BY c.Occupation;


-- 3. Rank ratings in Cuernavaca
WITH cuern AS (
    SELECT r.Restaurant_ID, rt.Consumer_ID, rt.Overall_Rating
    FROM ratings rt
    JOIN restaurants r ON rt.Restaurant_ID = r.Restaurant_ID
    WHERE r.City = 'Cuernavaca'
)
SELECT *,
       RANK() OVER (PARTITION BY Restaurant_ID ORDER BY Overall_Rating DESC) AS Ranking
FROM cuern;

-- 4. Add avg rating per consumer
SELECT Consumer_ID, Restaurant_ID, Overall_Rating,
       AVG(Overall_Rating) OVER (PARTITION BY Consumer_ID) AS avg_by_consumer
FROM ratings;

-- 5. Students with low budget → top 3 preferred cuisines
WITH s AS (
    SELECT Consumer_ID FROM consumers
    WHERE Occupation = 'Student' AND Budget = 'Low'
),
ranked AS (
    SELECT cp.Consumer_ID, cp.Preferred_Cuisine,
           ROW_NUMBER() OVER (PARTITION BY cp.Consumer_ID ORDER BY cp.Preferred_Cuisine) AS rn
    FROM consumer_preferences cp
    JOIN s ON cp.Consumer_ID = s.Consumer_ID
)
SELECT Consumer_ID, Preferred_Cuisine
FROM ranked
WHERE rn <= 3;

-- 6. Next restaurant rating (U1008)
WITH cte AS (
    SELECT Restaurant_ID, Overall_Rating,
           ROW_NUMBER() OVER (ORDER BY Restaurant_ID) AS rn
    FROM ratings
    WHERE Consumer_ID = 'U1008'
)
SELECT a.Restaurant_ID, a.Overall_Rating AS current_rating,
       b.Overall_Rating AS next_rating
FROM cte a
LEFT JOIN cte b ON b.rn = a.rn + 1;

-- 7. View: HighlyRatedMexicanRestaurants
CREATE VIEW HighlyRatedMexicanRestaurants AS
SELECT r.Restaurant_ID, r.Name, r.City
FROM restaurants r
JOIN restaurant_cuisines rc ON r.Restaurant_ID = rc.Restaurant_ID
JOIN ratings rt ON rt.Restaurant_ID = r.Restaurant_ID
WHERE rc.Cuisine = 'Mexican'
GROUP BY r.Restaurant_ID
HAVING AVG(rt.Overall_Rating) > 1.5;

-- 8. Consumers who like Mexican but never rated highly-rated Mexican restaurants
WITH pref AS (
    SELECT DISTINCT Consumer_ID
    FROM consumer_preferences
    WHERE Preferred_Cuisine = 'Mexican'
)
SELECT p.Consumer_ID
FROM pref p
WHERE NOT EXISTS (
    SELECT 1
    FROM ratings rt
    JOIN HighlyRatedMexicanRestaurants h ON rt.Restaurant_ID = h.Restaurant_ID
    WHERE rt.Consumer_ID = p.Consumer_ID
);

-- 9. Stored Procedure: GetRestaurantRatingsAboveThreshold
DELIMITER //

CREATE PROCEDURE GetRestaurantRatingsAboveThreshold(
    IN rid VARCHAR(50),
    IN minRating INT
)
BEGIN
    SELECT Consumer_ID, Overall_Rating, Food_Rating, Service_Rating
    FROM ratings
    WHERE Restaurant_ID = rid
      AND Overall_Rating >= minRating;
END //

DELIMITER ;

-- 10. Top 2 highest-rated restaurant per cuisine
WITH avg_r AS (
    SELECT rc.Cuisine, r.Name, r.City, r.Restaurant_ID,
           AVG(rt.Overall_Rating) AS avg_rating
    FROM restaurants r
    JOIN restaurant_cuisines rc ON r.Restaurant_ID = rc.Restaurant_ID
    JOIN ratings rt ON rt.Restaurant_ID = r.Restaurant_ID
    GROUP BY rc.Cuisine, r.Restaurant_ID
),
ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY Cuisine ORDER BY avg_rating DESC) AS rn
    FROM avg_r
)
SELECT Cuisine, Name, City, avg_rating
FROM ranked
WHERE rn <= 2;

-- 11) Create VIEW + CTE for Top 5 Consumers

-- Step 1 — Create the View
CREATE OR REPLACE VIEW ConsumerAverageRatings AS
SELECT 
    Consumer_ID,
    AVG(Overall_Rating) AS Avg_Overall_Rating
FROM ratings
GROUP BY Consumer_ID;


-- Step 2 — Top 5 Consumers Using CTE
WITH Top5 AS (
    SELECT 
        Consumer_ID,
        Avg_Overall_Rating
    FROM ConsumerAverageRatings
    ORDER BY Avg_Overall_Rating DESC
    LIMIT 5
)
SELECT 
    t.Consumer_ID,
    t.Avg_Overall_Rating,
    COUNT(DISTINCT rt.Restaurant_ID) AS Mexican_Restaurants_Rated
FROM Top5 t
LEFT JOIN ratings rt 
    ON t.Consumer_ID = rt.Consumer_ID
LEFT JOIN restaurant_cuisines rc 
    ON rc.Restaurant_ID = rt.Restaurant_ID
WHERE rc.Cuisine = 'Mexican'
GROUP BY t.Consumer_ID, t.Avg_Overall_Rating
ORDER BY t.Avg_Overall_Rating DESC;

-- 12) Stored Procedure: GetConsumerSegmentAndRestaurantPerformance

DELIMITER $$

CREATE PROCEDURE GetConsumerSegmentAndRestaurantPerformance(IN inConsumerID VARCHAR(50))
BEGIN
    
    -- 1) Show Spending Segment
    SELECT 
        Consumer_ID,
        Budget,
        CASE 
            WHEN Budget = 'Low' THEN 'Budget Conscious'
            WHEN Budget = 'Medium' THEN 'Moderate Spender'
            WHEN Budget = 'High' THEN 'Premium Spender'
            ELSE 'Unknown Budget'
        END AS Spending_Segment
    FROM consumers
    WHERE Consumer_ID = inConsumerID;
    

    -- 2) Restaurant Performance Breakdown
    SELECT
        r.Name AS Restaurant_Name,
        rt.Overall_Rating AS Consumer_Rating,
        
        -- Average of all ratings for that restaurant
        avgtable.Avg_Overall AS Restaurant_Average_Rating,
        
        CASE
            WHEN rt.Overall_Rating > avgtable.Avg_Overall THEN 'Above Average'
            WHEN rt.Overall_Rating = avgtable.Avg_Overall THEN 'At Average'
            ELSE 'Below Average'
        END AS Performance_Flag,
        
        -- Ranking for this consumer (highest rating = 1)
        RANK() OVER (ORDER BY rt.Overall_Rating DESC) AS Rating_Rank
        
    FROM ratings rt
    JOIN restaurants r ON r.Restaurant_ID = rt.Restaurant_ID
    
    -- subquery to compute restaurant avg ratings
    JOIN (
        SELECT 
            Restaurant_ID,
            AVG(Overall_Rating) AS Avg_Overall
        FROM ratings
        GROUP BY Restaurant_ID
    ) avgtable ON avgtable.Restaurant_ID = rt.Restaurant_ID
    
    WHERE rt.Consumer_ID = inConsumerID
    ORDER BY rt.Overall_Rating DESC;

END $$

DELIMITER ;


CALL GetConsumerSegmentAndRestaurantPerformance('U1001');
