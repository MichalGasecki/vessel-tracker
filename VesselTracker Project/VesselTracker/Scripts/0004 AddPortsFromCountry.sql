DROP PROCEDURE IF EXISTS dbo.AddPortsFromCountry

GO

CREATE PROCEDURE dbo.AddPortsFromCountry (@CountryID VARCHAR(10)) AS

--DECLARE @CountryID VARCHAR(10) = 'PL'

DECLARE @Page INT = 1
DECLARE @PageMax INT = dbo.Wytnij(dbo.Wytnij(dbo.Wytnij(dbo.Pobierz('https://www.vesselfinder.com/ports?country=' + @CountryID), '<span>page 1 / [0-9]+</span>'), '[0-9]+</span>'), '[0-9]+')

WHILE @Page <= @PageMax
BEGIN

	DECLARE @HTML NVARCHAR(MAX)

	IF @Page = 1
	SET @HTML = dbo.Pobierz('https://www.vesselfinder.com/ports?country=' + @CountryID)

	IF @Page > 1
	SET @HTML = dbo.Pobierz('https://www.vesselfinder.com/ports?page=' + CAST(@Page AS VARCHAR(10)) + '&country=' + @CountryID)

	SET @HTML = dbo.Wytnij(@HTML, '<section class="column listing">(.|\n)*?</section>')

	DECLARE @XML XML = TRY_CAST(@HTML AS XML);

	WITH dane AS
	(
		SELECT a.b.value('div[1]/a[1]/@href','NVARCHAR(100)') AS URL,
			   a.b.value('div[1]/a[1]/img[1]/@src','NVARCHAR(100)') AS PhotoURL,
			   a.b.value('div[2]/div[1]/h3[1]/a[1]/span[2]','NVARCHAR(100)') AS Name,
			   a.b.value('div[2]/div[2]/div[2]','NVARCHAR(100)') AS Country,
			   a.b.value('div[2]/div[3]/div[2]','NVARCHAR(100)') AS LOCODE
		FROM @xml.nodes ('section/div[contains(@class, ''list-row ports-row columns'')]') AS a(b)
	), gotowe AS
	(
		SELECT LOCODE,
		       Name,
			   (SELECT CountryID FROM Country WHERE Name = Country) AS CountryID,
			   IIF(PhotoURL NOT LIKE '%port-landscape@3.png', PhotoURL, NULL) AS PhotoURL,
			   'https://www.vesselfinder.com' + URL AS URL
		FROM dane
	)
	INSERT INTO Port
	SELECT LOCODE,
		   Name,
		   CountryID,
		   dbo.GetPortLocation(URL) AS Location,
		   PhotoURL,
		   dbo.PobierzObraz(PhotoURL) AS Photo,
		   URL
	FROM gotowe
	WHERE LOCODE NOT IN (SELECT LOCODE FROM Port)

	SET @Page = @Page + 1

END