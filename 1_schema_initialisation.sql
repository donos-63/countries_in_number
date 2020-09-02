-- REINIT DB --
DROP TABLE IF EXISTS country CASCADE;
DROP FUNCTION IF EXISTS random_between;
DROP FUNCTION IF EXISTS random_between_int;
DROP FUNCTION IF EXISTS random_between_dec;
DROP FUNCTION IF EXISTS set_creation_date;
DROP FUNCTION IF EXISTS get_density_by_country;
DROP TYPE IF EXISTS density_group CASCADE;


-- CREATE MAIN TABLE --
CREATE TABLE country (
   name TEXT PRIMARY KEY,
   population BIGINT NOT NULL,
   yearly_change DECIMAL NOT NULL,
   net_change INTEGER NOT NULL,
   density INTEGER NOT NULL,
   land_area INTEGER NOT NULL,
   migrants  INTEGER,
   fertilisation_rate DECIMAL ,
   medium_age INTEGER,
   urban_pop INTEGER,
   world_share DECIMAL,
   insertion_date TIMESTAMP WITH TIME ZONE
);


-- CREATE TOOL FUNCTIONS --
CREATE OR REPLACE FUNCTION random_between(low bigint ,high bigint, is_percent bool) RETURNS decimal 
LANGUAGE plpgsql
AS $$
/*
Return number between $low and $high as decimal number
params:
	-low : minimum random generator value
	-high : minimum random generator value
	-is_percent : value must be calculated as percent or not (compute decimal value)
*/
DECLARE
	decimal_multiplier int := 1;
BEGIN
	IF is_percent THEN 
		decimal_multiplier := 100;
	END IF;
	
	RETURN floor(random()* (high*decimal_multiplier-low*decimal_multiplier + 1) + low*decimal_multiplier)/decimal_multiplier;
END;
$$ 
;


CREATE OR REPLACE FUNCTION random_between_int(low bigint ,high bigint) RETURNS bigint 
LANGUAGE plpgsql
AS $$
/*
Return number between $low and $high as integer unmber (rounded to interger)
params:
	-low : minimum random generator value
	-high : minimum random generator value
*/
BEGIN
	RETURN cast(random_between(low, high, false) as bigint);
END;
$$ 
;


CREATE OR REPLACE FUNCTION random_between_dec(low bigint ,high bigint) RETURNS decimal 
LANGUAGE plpgsql
AS $$
/*
Return number between $low and $high as decimal umber, rounded to 2 digits after comma
params:
	-low : minimum random generator value
	-high : minimum random generator value
*/
BEGIN
	RETURN round(random_between(low, high, true), 2);
END;
$$ 
;

-- CREATE BRIEF PROCEDURE --

CREATE OR REPLACE PROCEDURE insert_random_country(country_name IN TEXT)
LANGUAGE plpgsql  
AS $proc_test$
/*
insert country with random stats with consitent data
example: country area = population*density
params:
	-country_name : name of the country
*/
DECLARE
    pop_total bigint :=  random_between_int(500,2000000000); --population between 10k to 3b
    yearly_change decimal :=  random_between_dec(-10,10); --yearly population change in %. Limited to 10%
    pop_density int := random_between_int(1,30000); --population per km²
BEGIN
    INSERT INTO country VALUES (
            country_name, --country name
            pop_total,    --population
            yearly_change, --yearly population change in %
            round(pop_total * yearly_change / 100),   ----yearly population number change, based on population and yearly change in %
            pop_density, --density of population per km²
            round(pop_total/pop_density), --land are in Km²
            random_between_int(1,  CAST(pop_total*10/100 as bigint)), -- number of migrants variation in 1 year, limited to 10% of the total amount of residents
            random_between_dec(0,8), --fertilisation rate bewteen 0 and 8
            random_between_int(30,70), --age average between 30 and 70 years old
            random_between_int(1,99), --urban population in % between 1 and 99
            random_between_dec(0,50) --world share between 0 and 50%
        );
END;
$proc_test$
;

-- CREATE BRIEF FUNCTION --

CREATE OR REPLACE FUNCTION get_country_by_name(country_name text) RETURNS SETOF country
LANGUAGE plpgsql
AS $func_test$
/*
return given $country_name values from country table
params:
	-country_name : name of the coutry
*/
BEGIN
    RETURN QUERY 
        SELECT * FROM country WHERE lower(country.name)= lower(country_name);
END;
$func_test$ 
;

-- CREATE BRIEF TRIGGER --

CREATE OR REPLACE FUNCTION set_creation_date() RETURNS TRIGGER
LANGUAGE plpgsql 
AS $trigg_test$  
/*
trigger to update insertion_date (timestamp) to new created row in country table
*/  
BEGIN
    UPDATE country 
    SET insertion_date = NOW()
    WHERE country.name = NEW.name;

    RETURN NULL;
EXCEPTION WHEN OTHERS THEN
	-- ALWAYS catch exception in trigger then :
	-- for example : store log in the database
	-- or keep operation complete : RETURN NULL;
	-- or throw the exception to stop the operation like this:
	RAISE exception 'set_creation_date failed';
	
	RETURN NULL;
END;
$trigg_test$
;

CREATE TRIGGER trigg_set_date AFTER INSERT ON country
    FOR EACH ROW EXECUTE PROCEDURE set_creation_date();
	
-- CREATE BRIEF DENSITY GROUPMENT FUNCTION-- 

CREATE TYPE density_group AS (group_quarter text, countries text);

CREATE OR REPLACE FUNCTION get_countries_by_density(quarter1_v_low INT, quarter2_low INT, quarter3_medium INT ) RETURNS SETOF density_group
LANGUAGE plpgsql  
AS $proc_test2$
/*
Function that group countries by density
params:
	-quarter1_v_low: first quarter between 0 and $quarter1_v_low
	-quarter2_low: second quarter between $quarter1_v_low and $quarter2_low
	-quarter3_medium: third quarter between $quarter2_low and $quarter3_medium
	-(implicit) last_quarter: fourth quarter superior than $third quarter
*/  
BEGIN
    IF quarter3_medium < quarter2_low OR quarter2_low < quarter1_v_low THEN
        RAISE exception 'bad quarters definition. Quarters must be superior to previously quarters';
    END IF;

    RETURN QUERY 
		SELECT 'quarter_1' as group_quarter,string_agg(country.name, ' ,') as country_group
		FROM country
		WHERE country.density <= quarter1_v_low
		UNION    
		SELECT 'quarter_2' as group_quarter,string_agg(country.name, ' ,') as country_group
		FROM country
		WHERE country.density > quarter1_v_low AND country.density <= quarter2_low
		UNION    
		SELECT 'quarter_3' as group_quarter,string_agg(country.name, ' ,') as country_group
		FROM country
		WHERE country.density > quarter2_low AND country.density <= quarter3_medium
			UNION    
		SELECT 'quarter_4' as group_quarter,string_agg(country.name, ' ,') as country_group
		FROM country
		WHERE country.density > quarter3_medium
		ORDER BY group_quarter;
END;
$proc_test2$
;

CREATE OR REPLACE FUNCTION get_density_by_country(country_name text, quarter1_v_low int, quarter2_low int, quarter3_medium int)
RETURNS TABLE (name text, population bigint, density int,  density_interpret text) LANGUAGE plpgsql
AS $func_density_country$
/*
Function that give density interpretation for a country
params:
	-country_name: label of the country
	-quarter1_v_low: first quarter between 0 and $quarter1_v_low
	-quarter2_low: second quarter between $quarter1_v_low and $quarter2_low
	-quarter3_medium: third quarter between $quarter2_low and $quarter3_medium
	-(implicit) last_quarter: fourth quarter superior than $third quarter3_medium
*/  
BEGIN 
    IF quarter3_medium < quarter2_low OR quarter2_low < quarter1_v_low THEN
        RAISE exception 'bad quarters definition. Quarters must be superior to previously quarters';
    END IF;
	
	RETURN QUERY
		SELECT country.name, country.population, country.density,
			CASE 
				WHEN country.density < quarter1_v_low THEN CONCAT('Density is > 0 to <=',quarter1_v_low,' : Very slow density')
				WHEN country.density < quarter2_low THEN CONCAT('Density is > ',quarter1_v_low,' AND <= ',quarter2_low,' : Low density')
				WHEN country.density < quarter3_medium THEN CONCAT('Density is >',quarter2_low,' AND <= ',quarter3_medium,' : Medium density')
				ELSE CONCAT('Density is > ',quarter3_medium,' : Hight density')
			END as demography
		FROM country
        WHERE lower(country.name)= lower(country_name);
END;
$func_density_country$

	