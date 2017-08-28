
-- Tests to run while loading the 160 files
--
select count(*) from ReviewsLog;

select * 
from FileLog
Order by FileLog.ProcessedDate desc ;

Select *, LEN(Name) from GetFiles(N'C:\Users\roble\Google Drive\dexio') 
Where CHARINDEX('.json', Name) > 0
Order by LastWriteTime asc
Go


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
		)' ;

--	WHERE [SchoolName] = ''Sabio'''

Print @sql_string ;

Exec(@sql_string) ;

GO


