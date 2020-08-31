-- TEST --

SELECT * FROM GetCountryByName('china');

CALL InsertRandomCountry('TomorrowLand');

SELECT name, insertion_date from GetCountryByName('TomorrowLand');

SELECT * from GetCountriesByDensity(100,200,400);