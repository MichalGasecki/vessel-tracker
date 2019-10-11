DROP PROCEDURE IF EXISTS dbo.AddVessels

GO

CREATE PROCEDURE dbo.AddVessels AS

DECLARE @CountryID NVARCHAR(200)

DECLARE countries CURSOR FOR SELECT CountryID FROM Country ORDER BY CountryID

OPEN countries;
FETCH NEXT FROM countries INTO @CountryID
WHILE @@FETCH_STATUS=0
BEGIN

EXEC	dbo.AddVesselsFromCountry
		@CountryID = @CountryID

PRINT @CountryID

FETCH NEXT FROM countries INTO @CountryID
END
CLOSE countries
DEALLOCATE countries