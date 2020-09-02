-- TEST --
-- get country by name
SELECT * FROM get_country_by_name('china');

-- insert a country with random data
CALL insert_random_country('TomorrowLand');

-- call procedure to get country by name
SELECT name, insertion_date from get_country_by_name('TomorrowLand');

-- get noutries grouped by density
SELECT * from get_countries_by_density(100,200,400);

-- get density interpretation for a country 
SELECT * FROM get_density_by_country('TomorrowLand', 100, 200, 1500);