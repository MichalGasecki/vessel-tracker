DROP FUNCTION IF EXISTS dbo.GetPortLocation

GO

CREATE FUNCTION dbo.GetPortLocation (@URL NVARCHAR(200))
RETURNS GEOGRAPHY
AS
BEGIN

--DECLARE @URL NVARCHAR(200) = 'https://www.vesselfinder.com/ports/HEL-POLAND-23889'

DECLARE @PortLocation GEOGRAPHY

DECLARE @HTML NVARCHAR(MAX) = dbo.Pobierz(@URL)

SET @HTML = dbo.Wytnij(@HTML, '<table class="tparams">(.|\n)*?</table>')

DECLARE @XML XML = TRY_CAST(@HTML AS XML);

WITH dane AS
(
	SELECT a.b.value('tr[1]/td[2]/a[1]','NVARCHAR(100)') AS Coordinates
	FROM @xml.nodes ('table/tbody') AS a(b)
), gotowe AS
(
SELECT Coordinates,
	   SUBSTRING(Coordinates, 1, CHARINDEX('/', Coordinates) - 1) AS Latitude,
       SUBSTRING(Coordinates, CHARINDEX('/', Coordinates) + 1, LEN(Coordinates)) AS Longitude
FROM dane
), gotowe_lokalizacja AS
(
SELECT Coordinates,
	   IIF(Latitude LIKE '%N%', dbo.Wytnij(Latitude, '[0-9.]+'), '-' + dbo.Wytnij(Latitude, '[0-9.]+')) AS Latitude,
	   IIF(Longitude LIKE '%E%', dbo.Wytnij(Longitude, '[0-9.]+'), '-' + dbo.Wytnij(Longitude, '[0-9.]+')) AS Longitude
FROM gotowe
)
SELECT @PortLocation = GEOGRAPHY::Point(Latitude, Longitude, 4326)
FROM gotowe_lokalizacja

RETURN @PortLocation

END