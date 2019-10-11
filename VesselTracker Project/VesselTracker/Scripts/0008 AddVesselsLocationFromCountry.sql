DROP PROCEDURE IF EXISTS dbo.AddVesselsLocationFromCountry

GO

CREATE PROCEDURE dbo.AddVesselsLocationFromCountry (@CountryID VARCHAR(10)) AS

--DECLARE @CountryID VARCHAR(10) = 'PL'

DECLARE @IMO INT
DECLARE @MMSI INT
DECLARE @URL NVARCHAR(200)

DECLARE vessels CURSOR FOR SELECT IMO, MMSI, URL
                           FROM Vessel
						   WHERE CountryID = @CountryID
						   ORDER BY IMO

OPEN vessels;
FETCH NEXT FROM vessels INTO @IMO, @MMSI, @URL
WHILE @@FETCH_STATUS=0
BEGIN

EXEC	dbo.AddVesselLocation
		@IMO = @IMO,
		@MMSI = @MMSI,
		@URL = @URL

PRINT @URL

FETCH NEXT FROM vessels INTO @IMO, @MMSI, @URL
END
CLOSE vessels
DEALLOCATE vessels