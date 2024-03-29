DROP PROCEDURE IF EXISTS dbo.AddVesselsFromCountry

GO

CREATE PROCEDURE dbo.AddVesselsFromCountry (@CountryID VARCHAR(10)) AS

--DECLARE @CountryID VARCHAR(10) = 'PL'

DECLARE @Page INT = 1
DECLARE @PageMax INT = dbo.Wytnij(dbo.Wytnij(dbo.Podstaw(dbo.Wytnij(dbo.Pobierz('https://www.vesselfinder.com/vessels?flag=' + @CountryID), '<span>page 1 / [0-9,]+</span>'), ',', ''), '[0-9]+</span>'), '[0-9]+')

WHILE @Page <= @PageMax
BEGIN

	DECLARE @HTML NVARCHAR(MAX) = dbo.Pobierz('https://www.vesselfinder.com/vessels?page=' + CAST(@Page AS VARCHAR(10)) + '&flag=' + @CountryID)

	SET @HTML = dbo.Wytnij(@HTML, '<tbody>(.|\n)*?</tbody>')

	DECLARE @XML XML = TRY_CAST(@HTML AS XML);

	WITH dane AS
	(
		SELECT a.b.value('td[1]/a[1]/@href','NVARCHAR(100)') AS URL,
			   a.b.value('td[1]/a[1]/img[1]/@src','NVARCHAR(100)') AS PhotoURL,
			   a.b.value('td[2]/a[1]','NVARCHAR(100)') AS Name,
			   a.b.value('td[2]/a[1]/span[1]/@title','NVARCHAR(100)') AS Country,
			   a.b.value('td[2]/small[1]','NVARCHAR(100)') AS Type,
			   a.b.value('td[3]','NVARCHAR(100)') AS Built,
			   a.b.value('td[4]','NVARCHAR(100)') AS GT,
			   a.b.value('td[5]','NVARCHAR(1000)') AS DWT,
			   a.b.value('td[6]','NVARCHAR(1000)') AS Size
		FROM @xml.nodes ('tbody/tr') AS a(b)
	), gotowe AS
	(
		SELECT dbo.Wytnij(URL, '[0-9]{7}') AS IMO,
			   dbo.Wytnij(URL, '[0-9]{9}') AS MMSI,
			   IIF(Name != '0', Name, NULL) AS Name,
			   IIF(Type != 'Unknown', Type, NULL) AS Type,
			   (SELECT CountryID FROM Country WHERE Name = Country) AS CountryID,
			   IIF(Built != '-', Built, NULL) AS Built,
			   IIF(GT != '-', GT, NULL) AS GT,
			   IIF(DWT != '-', DWT, NULL) AS DWT,
			   IIF(Size != '-', Size, NULL) AS Size,
			   IIF(PhotoURL NOT LIKE '%cool-ship2@2.png', LEFT(PhotoURL, LEN(PhotoURL) - 1) + '1', NULL) AS PhotoURL,
			   'https://www.vesselfinder.com' + URL AS URL
		FROM dane
	)
	INSERT INTO Vessel
	SELECT IMO,
		   MMSI,
		   Name,
		   Type,
		   CountryID,
		   Built,
		   GT,
		   DWT,
		   Size,
		   PhotoURL,
		   NULL AS Photo,
		   --dbo.PobierzObraz(PhotoURL) AS Photo,
		   URL
	FROM gotowe
	WHERE Name IS NOT NULL AND (MMSI NOT IN (SELECT MMSI FROM Vessel) OR
								 IMO NOT IN (SELECT IMO FROM Vessel))

	SET @Page = @Page + 1

END