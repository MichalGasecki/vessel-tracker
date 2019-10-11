DROP PROCEDURE IF EXISTS dbo.AddCountries

GO

CREATE PROCEDURE dbo.AddCountries AS

DECLARE @HTML NVARCHAR(MAX) = dbo.Pobierz('https://www.vesselfinder.com/vessels')

SET @HTML = dbo.Wytnij(@HTML, '<select id="advsearch-ship-flag" name="flag">(.|\n)*?</select>')

DECLARE @XML XML = TRY_CAST(@HTML AS XML);

WITH dane AS
(
	SELECT a.b.value('@value','NVARCHAR(100)') AS CountryID,
	       a.b.value('.','NVARCHAR(100)') AS Name
	FROM @xml.nodes ('select/option') AS a(b)
)
INSERT INTO Country
SELECT UPPER(CountryID) AS CountryID,
       Name
FROM dane
WHERE CountryID != '-' AND CountryID NOT IN (SELECT CountryID FROM Country)