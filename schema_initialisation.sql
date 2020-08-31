-- REINIT DB --
DROP TABLE IF EXISTS country CASCADE;
DROP FUNCTION IF EXISTS random_between;
DROP FUNCTION IF EXISTS random_between_int;
DROP FUNCTION IF EXISTS random_between_dec;
DROP FUNCTION IF EXISTS set_creation_date;
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

CREATE OR REPLACE PROCEDURE InsertRandomCountry(country_name IN TEXT)
LANGUAGE plpgsql  
AS $proc_test$
/*
insert country with random stats with consitent data
params:
	-country_name : name of the country
*/
DECLARE
    pop_total bigint :=  random_between_int(10000,2000000000); --population between 1k to 3b
    yearly_change decimal :=  random_between_dec(-10,10); --yearly population change in %
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

CREATE OR REPLACE FUNCTION GetCountryByName(country_name text) RETURNS SETOF country
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
	
-- CREATE BRIEF DENSITY GROUPMENT -- 

CREATE TYPE density_group AS (group_quarter text, countries text);

CREATE OR REPLACE FUNCTION GetCountriesByDensity(max_first_quarter INT, max_second_quarter INT, max_third_quarter INT ) RETURNS SETOF density_group
LANGUAGE plpgsql  
AS $proc_test2$
/*
Function that group countries by density
params:
	-max_first_quarter: first quarter between 0 and $max_first_quarter
	-max_second_quarter: second quarter between $max_first_quarter and $max_second_quarter
	-max_third_quarter: third quarter between $max_second_quarter and $max_third_quarter
	-(implicit) last_quarter: fourth quarter superior than $third quarter
*/  
BEGIN
    IF max_third_quarter < max_second_quarter OR max_second_quarter < max_first_quarter THEN
        RAISE exception 'bad quarters definition. All quarters must be superior to previously quarters';
    END IF;

    RETURN QUERY 
		SELECT 'quarter_1' as group_quarter,string_agg(country.name, ' ,') as country_group
		FROM country
		WHERE country.density <= max_first_quarter
		UNION    
		SELECT 'quarter_2' as group_quarter,string_agg(country.name, ' ,') as country_group
		FROM country
		WHERE country.density > max_first_quarter AND country.density <= max_second_quarter
		UNION    
		SELECT 'quarter_3' as group_quarter,string_agg(country.name, ' ,') as country_group
		FROM country
		WHERE country.density > max_second_quarter AND country.density <= max_third_quarter
			UNION    
		SELECT 'quarter_4' as group_quarter,string_agg(country.name, ' ,') as country_group
		FROM country
		WHERE country.density > max_third_quarter
		ORDER BY group_quarter;
END;
$proc_test2$
;

	