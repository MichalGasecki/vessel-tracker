EXEC dbo.CreateTables

-- IMPORT COUNTRIES FROM XML

DECLARE @XMLCountry XML

DECLARE @result INT
EXEC master.dbo.xp_fileexist 'C:\Countries.xml', @result OUTPUT
SELECT CAST(@result AS BIT)

IF @result = 1
SELECT @XMLCountry = Country
FROM OPENROWSET (BULK 'C:\Countries.xml', SINGLE_BLOB) AS Countries(Country)

INSERT INTO Country
SELECT Countries.Country.value('CountryID[1]','NVARCHAR(100)') AS CountryID,
       Countries.Country.value('Name[1]','NVARCHAR(100)') AS Name
FROM @XMLCountry.nodes ('Country') AS Countries(Country)

-- IMPORT PORTS FROM XML

DECLARE @XMLPort XML

EXEC master.dbo.xp_fileexist 'C:\Ports.xml', @result OUTPUT
SELECT CAST(@result AS BIT)

IF @result = 1
SELECT @XMLPort = Port
FROM OPENROWSET (BULK 'C:\Ports.xml', SINGLE_BLOB) AS Ports(Port);

WITH data AS
(
	SELECT Ports.Port.value('LOCODE[1]','NVARCHAR(200)') AS LOCODE,
		   Ports.Port.value('Name[1]','NVARCHAR(200)') AS Name,
		   Ports.Port.value('CountryID[1]','NVARCHAR(200)') AS CountryID,
		   Ports.Port.value('Lat[1]','NVARCHAR(100)') AS Lat,
		   Ports.Port.value('Long[1]','NVARCHAR(100)') AS Long,
		   Ports.Port.value('PhotoURL[1]','NVARCHAR(200)') AS PhotoURL,
		   Ports.Port.value('Photo[1]','VARBINARY(MAX)') AS Photo,
		   Ports.Port.value('URL[1]','NVARCHAR(200)') AS URL
	FROM @XMLPort.nodes ('Port') AS Ports(Port)
)
INSERT INTO Port
SELECT LOCODE
      ,Name
	  ,CountryID
	  ,IIF(Lat != NULL AND Long != NULL, GEOGRAPHY::Point(Lat, Long, 4326), NULL) AS Location
	  ,PhotoURL
	  ,Photo
	  ,URL
FROM data

-- IMPORT PORTS WITH PHOTOS FROM XML

DECLARE @XMLPort XML

EXEC master.dbo.xp_fileexist 'C:\Ports (with photos).xml', @result OUTPUT
SELECT CAST(@result AS BIT)

IF @result = 1
SELECT @XMLPort = Port
FROM OPENROWSET (BULK 'C:\Ports (with photos).xml', SINGLE_BLOB) AS Ports(Port);

WITH data AS
(
	SELECT Ports.Port.value('LOCODE[1]','NVARCHAR(200)') AS LOCODE,
		   Ports.Port.value('Name[1]','NVARCHAR(200)') AS Name,
		   Ports.Port.value('CountryID[1]','NVARCHAR(200)') AS CountryID,
		   Ports.Port.value('Lat[1]','NVARCHAR(100)') AS Lat,
		   Ports.Port.value('Long[1]','NVARCHAR(100)') AS Long,
		   Ports.Port.value('PhotoURL[1]','NVARCHAR(200)') AS PhotoURL,
		   Ports.Port.value('Photo[1]','VARBINARY(MAX)') AS Photo,
		   Ports.Port.value('URL[1]','NVARCHAR(200)') AS URL
	FROM @XMLPort.nodes ('Port') AS Ports(Port)
)
INSERT INTO Port
SELECT LOCODE
      ,Name
	  ,CountryID
	  ,IIF(Lat != NULL AND Long != NULL, GEOGRAPHY::Point(Lat, Long, 4326), NULL) AS Location
	  ,PhotoURL
	  ,Photo
	  ,URL
FROM data

-- IMPORT VESSELS FROM XML

DECLARE @XMLVessel XML

EXEC master.dbo.xp_fileexist 'C:\Vessels.xml', @result OUTPUT
SELECT CAST(@result AS BIT)

IF @result = 1
SELECT @XMLVessel = Vessel
FROM OPENROWSET (BULK 'C:\Vessels.xml', SINGLE_BLOB) AS Vessels(Vessel);

WITH data AS
(
	SELECT Vessels.Vessel.value('IMO[1]','NVARCHAR(100)') AS IMO,
		   Vessels.Vessel.value('MMSI[1]','NVARCHAR(100)') AS MMSI,
		   Vessels.Vessel.value('Name[1]','NVARCHAR(100)') AS Name,
		   Vessels.Vessel.value('Type[1]','NVARCHAR(100)') AS Type,
		   Vessels.Vessel.value('CountryID[1]','NVARCHAR(100)') AS CountryID,
		   Vessels.Vessel.value('Built[1]','NVARCHAR(100)') AS Built,
		   Vessels.Vessel.value('GT[1]','NVARCHAR(100)') AS GT,
		   Vessels.Vessel.value('DWT[1]','NVARCHAR(100)') AS DWT,
		   Vessels.Vessel.value('Size[1]','NVARCHAR(100)') AS Size,
		   Vessels.Vessel.value('PhotoURL[1]','NVARCHAR(200)') AS PhotoURL,
		   Vessels.Vessel.value('URL[1]','NVARCHAR(200)') AS URL
	FROM @XMLVessel.nodes ('Port') AS Vessels(Vessel)
)
INSERT INTO Vessel
SELECT IMO
	  ,MMSI
	  ,Name
	  ,Type
	  ,CountryID
	  ,Built
	  ,GT
	  ,DWT
	  ,Size
	  ,PhotoURL
	  ,NULL AS Photo
	  ,URL
FROM data