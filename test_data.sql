-- TEST --

SELECT * FROM get_country_by_name('china');

CALL insert_random_country('TomorrowLand');

SELECT name, insertion_date from get_country_by_name('TomorrowLand');

SELECT * from get_countries_by_density(100,200,400);