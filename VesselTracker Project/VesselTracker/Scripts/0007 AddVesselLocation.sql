DROP PROCEDURE IF EXISTS dbo.AddVesselLocation

GO

CREATE PROCEDURE dbo.AddVesselLocation (@IMO INT, @MMSI INT, @URL NVARCHAR(200)) AS

--DECLARE @IMO INT = 2610050
--DECLARE @MMSI INT = 261005080
--DECLARE @URL NVARCHAR(200) = 'https://www.vesselfinder.com/vessels/LAILA-II-IMO-8700084-MMSI-0'

DECLARE @HTML NVARCHAR(MAX) = dbo.Pobierz(@URL)

SET @HTML = dbo.Wytnij(@HTML, '<h2 class="bar">AIS Data</h2>(\n)*<table class="tparams">(.|\n)*?</table>')
SET @HTML = dbo.Podstaw(@HTML, '<h2 class="bar">AIS Data</h2>(\n)*', '')
SET @HTML = dbo.Podstaw(@HTML, '&deg;', '')

DECLARE @XML XML = TRY_CAST(@HTML AS XML);

WITH dane AS
(
	SELECT a.b.value('tr[3]/td[2]','NVARCHAR(100)') AS Destination,
		   a.b.value('tr[9]/td[2]','NVARCHAR(100)') AS Parameters,
		   a.b.value('tr[10]/td[2]','NVARCHAR(100)') AS Coordinates,
		   a.b.value('tr[11]/td[2]','NVARCHAR(100)') AS LastReport
	FROM @xml.nodes ('table/tbody') AS a(b)
), gotowe AS
(
SELECT Destination,
       Parameters,
	   SUBSTRING(Parameters, 1, CHARINDEX('/', Parameters) - 1) AS Course,
       SUBSTRING(Parameters, CHARINDEX('/', Parameters) + 1, LEN(Parameters)) AS Speed,
	   Coordinates,
	   SUBSTRING(Coordinates, 1, CHARINDEX('/', Coordinates) - 1) AS Latitude,
       SUBSTRING(Coordinates, CHARINDEX('/', Coordinates) + 1, LEN(Coordinates)) AS Longitude,
	   IIF(LastReport != ' -', CAST(LEFT(LastReport, LEN(LastReport) - 4) AS DATETIME), NULL) AS LastReport
FROM dane
), gotowe_lokalizacja AS
(
SELECT CAST(@IMO AS VARCHAR(10)) + '_' + CAST(@MMSI AS VARCHAR(10)) AS VesselID,
       IIF(Destination != '-', Destination, NULL) AS Destination,
       Parameters,
	   IIF(Course != '-', Course, NULL) AS Course,
	   dbo.Podstaw(Speed, ' kn', '') AS Speed,
	   IIF(Latitude LIKE '%N%', dbo.Wytnij(Latitude, '[0-9.]+'), '-' + dbo.Wytnij(Latitude, '[0-9.]+')) AS Latitude,
	   IIF(Longitude LIKE '%E%', dbo.Wytnij(Longitude, '[0-9.]+'), '-' + dbo.Wytnij(Longitude, '[0-9.]+')) AS Longitude,
	   LastReport
FROM gotowe
)
INSERT INTO Location
SELECT VesselID,
       Destination,
       Course,
	   IIF(LEN(dbo.Wytnij(Speed, '[0-9]+')) != 0, dbo.Wytnij(Speed, '[0-9]+'), NULL) AS Speed,
	   --IIF(Latitude NOT LIKE '%0.0', Latitude, NULL) AS Latitude,
	   --IIF(Longitude NOT LIKE '%0.0', Longitude, NULL) AS Longitude,
	   IIF(Latitude NOT LIKE '%0.0' AND Latitude NOT LIKE '%0.0',
	       GEOGRAPHY::Point(Latitude, Longitude, 4326),
		   NULL) AS Location,
	   LastReport,
	   GETUTCDATE() AS UpdateTime
FROM gotowe_lokalizacja
WHERE NOT EXISTS (SELECT VesselID FROM Location
                                  WHERE VesselID = gotowe_lokalizacja.VesselID
								  AND LastReport = gotowe_lokalizacja.LastReport)