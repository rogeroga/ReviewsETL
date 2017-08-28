--
-- DDL SQL script to manage the CLR functions used to load, extract 
-- the dev bootcamp school reviews data
--

Use [Sabio]
Go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- Temporary test table input
-- 
drop table [dbo].[Input]
go

create table [dbo].[Input]
(
	SchoolName varchar(200),
	Url varchar(200),
	RatingCount varchar(200),
	Rating varchar(200),
	RatingContent varchar(200),
	ReviewsHtml varchar(MAX),
	CurrentUrl varchar(200),
	Error varchar(200)
)
GO


-------------------------
-------------------------
-- LOAD DATA

INSERT INTO [dbo].[Input]
	SELECT TOP(100) [SchoolName], [Url], [RatingCount], [Rating], [RatingContent], [ReviewsHtml], [CurrentUrl], [Error] 
	FROM OPENROWSET (BULK 'C:\Users\roble\Documents\Sabio\schools.json', SINGLE_CLOB) as j
	CROSS APPLY OPENJSON(BulkColumn, '$.rows')
	WITH ( 
			SchoolName nvarchar(200) '$[1]',
			Url nvarchar(200) '$[2]',
			RatingCount nvarchar(200) '$[3]',
			Rating varchar(200) '$[4]',
			RatingContent varchar(200) '$[5]',
			ReviewsHtml varchar(MAX) '$[6]',
			CurrentUrl varchar(200) '$[7]',
			Error varchar(200) '$[8]'
		) 
GO



-- Insert Sabio Rows
--
INSERT INTO [dbo].[Input]
SELECT [SchoolName], [Url], [RatingCount], [Rating], [RatingContent], [ReviewsHtml], [CurrentUrl], [Error] 
FROM OPENROWSET (BULK 'C:\Users\roble\Documents\Sabio\schools.json', SINGLE_CLOB) as j
CROSS APPLY OPENJSON(BulkColumn, '$.rows')
 WITH ( 
			SchoolName varchar(200) '$[1]',
			Url varchar(200) '$[2]',
			RatingCount varchar(200) '$[3]',
			Rating varchar(200) '$[4]',
			RatingContent varchar(200) '$[5]',
			ReviewsHtml varchar(MAX) '$[6]',
			CurrentUrl varchar(200) '$[7]',
			Error varchar(200) '$[8]'
		) 
WHERE [SchoolName] = 'Sabio' 

GO


Use [Sabio]
go


SELECT TOP (10) [SchoolName]
      ,[Url]
      ,[RatingCount]
      ,[Rating]
      ,[RatingContent]
      ,[ReviewsHtml]
      ,[CurrentUrl]
      ,[Error]
  FROM [Sabio].[dbo].[Input] 
go



declare @ReviewHtml nvarchar(MAX);

select TOP(1)
    @ReviewHtml = Input.[ReviewsHtml]
from
    [Sabio].[dbo].[Input] Input


select * from GetReviews(@ReviewHtml);

go



SELECT [SchoolName], [Url], [RatingCount], [Rating], [RatingContent], [ReviewsHtml], [CurrentUrl], [Error] 
FROM OPENROWSET (BULK 'C:\Users\roble\Documents\Sabio\schools.json', SINGLE_CLOB) as j
CROSS APPLY OPENJSON(BulkColumn, '$.rows')
 WITH ( 
			SchoolName varchar(200) '$[1]',
			Url varchar(200) '$[2]',
			RatingCount varchar(200) '$[3]',
			Rating varchar(200) '$[4]',
			RatingContent varchar(200) '$[5]',
			ReviewsHtml varchar(MAX) '$[6]',
			CurrentUrl varchar(200) '$[7]',
			Error varchar(200) '$[8]'
		) 
WHERE [SchoolName] = 'Sabio' 

GO




SELECT [SchoolName], [Url], [RatingCount], [Rating], [RatingContent], [ReviewsHtml], [CurrentUrl], [Error] 
-- FROM OPENROWSET (BULK 'C:\Users\roble\Documents\Sabio\schools.json', SINGLE_CLOB) as j
-- FROM OPENROWSET (BULK 'C:\Users\roble\Google Drive\dexio\20170219_1730_cr_schools_to_details_v1_daily_-_cr_schools_v1.json', SINGLE_CLOB) as j
FROM OPENROWSET (BULK @FName, SINGLE_CLOB) as j
CROSS APPLY OPENJSON(BulkColumn, '$.rows')
 WITH ( 
			SchoolName varchar(200) '$[1]',
			Url varchar(200) '$[2]',
			RatingCount varchar(200) '$[3]',
			Rating varchar(200) '$[4]',
			RatingContent varchar(200) '$[5]',
			ReviewsHtml varchar(MAX) '$[6]',
			CurrentUrl varchar(200) '$[7]',
			Error varchar(200) '$[8]'
		) 
WHERE [SchoolName] = 'Sabio' 

GO


select *, LEN(Name) from GetFiles(N'C:\Users\roble\Google Drive\dexio') 
where CHARINDEX('.json', Name) > 0
order by LastWriteTime asc
go

Declare @FName nvarchar(MAX) = N'C:\Users\roble\Google Drive\dexio\20170220_0406_cr_schools_to_details_v1_daily_-_cr_schools_v1.json' ;
Declare @sql_string nvarchar(max) = 
	N'SELECT [SchoolName], [Url], [RatingCount], [Rating], [RatingContent], [ReviewsHtml], [CurrentUrl], [Error] 
	FROM OPENROWSET (BULK ' + Quotename(@FName, nchar(39)) + ', SINGLE_CLOB) as j
	CROSS APPLY OPENJSON(BulkColumn, ''$.rows'')
	WITH ( 
			SchoolName varchar(200) ''$[1]'',
			Url varchar(200) ''$[2]'',
			RatingCount varchar(200) ''$[3]'',
			Rating varchar(200) ''$[4]'',
			RatingContent varchar(200) ''$[5]'',
			ReviewsHtml varchar(MAX) ''$[6]'',
			CurrentUrl varchar(200) ''$[7]'',
			Error varchar(200) ''$[8]''
		) 
	WHERE [SchoolName] = ''Sabio''' ;

Print @sql_string ;

Exec(@sql_string) ;

GO



Declare @FName nvarchar(MAX) = N'C:\Users\roble\Google Drive\dexio\20170220_0406_cr_schools_to_details_v1_daily_-_cr_schools_v1.json' ;
Select @FName as FileName ;
GO

