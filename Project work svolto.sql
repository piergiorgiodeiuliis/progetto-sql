CREATE DATABASE Chimica;

USE Chimica;

CREATE TABLE dbo.EsperimentiStaging(
	IdEsperimento VARCHAR(255),
	Data VARCHAR(255),
	Operatore VARCHAR(255),
	Valore VARCHAR(255),
	Molecola VARCHAR(255) );

BULK INSERT dbo.EsperimentiStaging
FROM 'C:\Users\ianto\Desktop\Videocorsi\SQL Academy\Script lezioni\Project work fine corso\Esperimenti.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ';',
	ROWTERMINATOR = '\n');

SELECT *
FROM    dbo.EsperimentiStaging;

CREATE TABLE dbo.Esperimenti(
	IdEsperimento INT NOT NULL PRIMARY KEY,
	Data DATE NOT NULL,
	Operatore VARCHAR(255) NOT NULL,
	Valore DECIMAL(18,10) NOT NULL,
	Molecola VARCHAR(255) NOT NULL);


/*
01/01/2020 -> 2020-01-01
0,728909901 -> 0.728909901
*/

INSERT INTO dbo.Esperimenti(IdEsperimento,
	Data,Operatore, Valore, Molecola)
SELECT CAST(IdEsperimento AS INT) AS IdEsperimento, 
       CAST(CONCAT(RIGHT(Data,4),
		      '-',
			  SUBSTRING(Data,4,2),
			  '-',
			  LEFT(Data,2)) AS DATE) AS Data,
	   Operatore,
	   CAST(REPLACE(REPLACE(Valore,'.',''),',','.') AS DECIMAL(18,10)),
	   Molecola
FROM    dbo.EsperimentiStaging;

--Prima versione
WITH DatiPre AS (
	SELECT Operatore, AVG(Valore) as MediaValorePre
	FROM   dbo.Esperimenti
	WHERE  
	(
		(Molecola LIKE 'AB%'
		AND Molecola LIKE '%D')
		or 
		(Molecola LIKE 'F%'
		AND Molecola NOT LIKE '%P'
		)
	)
	AND 
	Data < '20200501'
	GROUP BY Operatore
	),
	DatiPost AS (
		SELECT Operatore, AVG(Valore) as MediaValorePost
		FROM   dbo.Esperimenti
		WHERE  
		(
			(Molecola LIKE 'AB%'
			AND Molecola LIKE '%D')
			or 
			(Molecola LIKE 'F%'
			AND Molecola NOT LIKE '%P'
			)
		)
		AND 
		Data >= '20200501'
		GROUP BY Operatore
	)
SELECT DatiPre.Operatore, MediaValorePre, MediaValorePost, 
MediaValorePost-MediaValorePre AS DifferenzaPostPre,
(MediaValorePost-MediaValorePre)/MediaValorePre AS DifferenzaPercentuale
FROM  DatiPre 
inner join DatiPost
	on DatiPre.Operatore = DatiPost.Operatore;


--SECONDA VERSIONE
WITH DatiFiltrati AS (
	SELECT *
	FROM   dbo.Esperimenti
	WHERE   (Molecola LIKE 'AB%'
		AND Molecola LIKE '%D')
		or 
		(Molecola LIKE 'F%'
		AND Molecola NOT LIKE '%P'
		)
	), 
DatiPre AS (
	SELECT Operatore, AVG(Valore) as MediaValorePre
	FROM   DatiFiltrati
	WHERE  Data < '20200501'
	GROUP BY Operatore
	),
DatiPost AS (
		SELECT Operatore, AVG(Valore) as MediaValorePost
		FROM   DatiFiltrati
		WHERE  Data >= '20200501'
		GROUP BY Operatore
	)
SELECT DatiPre.Operatore, MediaValorePre, MediaValorePost, 
MediaValorePost-MediaValorePre AS DifferenzaPostPre,
(MediaValorePost-MediaValorePre)/MediaValorePre AS ScostamentoPercentuale
FROM  DatiPre 
inner join DatiPost
	on DatiPre.Operatore = DatiPost.Operatore;


--TERZA VERSIONE
with DatiPerOperatore AS (
	SELECT Operatore,
		AVG(CASE WHEN Data < '20200501' THEN Valore ELSE NULL END) AS MediaPre,
		AVG(CASE WHEN Data >= '20200501' THEN Valore ELSE NULL END) AS MediaPost
	FROM   dbo.Esperimenti
	WHERE   (Molecola LIKE 'AB%'
		AND Molecola LIKE '%D')
		or 
		(Molecola LIKE 'F%'
		AND Molecola NOT LIKE '%P'
		)
	GROUP BY Operatore)
SELECT Operatore, 
	MediaPre,
	MediaPost, 
	MediaPost-MediaPre as Differenza,
	CASE WHEN MediaPre = 0 THEN NULL ELSE ( MediaPost-MediaPre)/MediaPre END AS ScostamentoPercentuale
FROM DatiPerOperatore;