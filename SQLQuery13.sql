
-- Common queries
--

Use Outcomes;
GO

SELECT TOP (1000) * FROM [Outcomes].[dbo].[FileLog]
 Order by [ProcessedDate] desc ;

SELECT top(1000) * FROM [dbo].[Stage]
GO

SELECT * FROM [dbo].[Schools]
GO

select max(len(SchoolName))
  FROM [dbo].[Schools]
GO

select count(*) from dbo.ReviewsLog 
go

SELECT * FROM [dbo].[ReviewDifferences]
GO

begin transaction
update [dbo].[FileLog]
	set enabled = 1 
	where status = 1;
commit ;
go

update dbo.FileLog
set enabled = 0
-- select l.FileLogId, temp.sum_loaded, l.FileName
from
	(
		select f.FileLogId, sum(s.LoadedReviews) as sum_loaded
		from dbo.FileLog f inner join dbo.Stage s on f.FileLogId = s.FileLogId
		group by f.FileLogId  
	) as temp,
	 dbo.FileLog l
where
	l.FileLogId = temp.FileLogId
	and temp.sum_loaded < 5124 ;




-- Threshold 
--
select sum(s.LoadedReviews) as sum_loaded
from dbo.FileLog f, dbo.Stage s 
where f.FileLogId = s.FileLogId
	and f.FileLogId = 1;

-- API Testing
-- 

Select * From GetFiles(N'C:\Users\roble\Google Drive\dexio') 
	Where CHARINDEX(N'.json', Name) > 0
	Order by LastWriteTime asc ;
GO

SELECT @Rows=@@ROWCOUNT

Declare @Sql_String nvarchar(max) = 'Use ' + '[Outcomes]'; 

	Print @Sql_String ;
	-- Execute it to load the new input file into the Stage table and split Json content into columns
	--
	-- EXECUTE sp_executesql @Sql_String ;
	EXECUTE (@Sql_String)

	GO

	select count(*) from dbo.FileLog ;
	GO


declare @query varchar(1000),@dbname varchar(50),@tableName varchar(50) ;


set @dbname='Outcomes'
set @tableName='Schools'
set @query = 'select * from ' +@dbname+'.[dbo].'+@tableName
exec (@query)
go



Declare @AddedIds nvarchar(max),
		@DeletedIds nvarchar(max),
		@TmpNextId int,
		@TmpMaxId int,
		@Loop int;

Select @AddedIds = COALESCE(@AddedIds + ', ', '') + CAST(ReviewId as nvarchar) 
From [dbo].[ReviewsLog]
Where StageID = 1 AND FileLogId =  1 And SchoolId = 298;


Select @AddedIds ;

Select *
From [dbo].[ReviewsLog]
Where StageID = 1 AND FileLogId = 1 And SchoolId = 298;

GO


ALTER TABLE dbo.Stage 
ADD CONSTRAINT LoadedReviews_Default  
DEFAULT 0 FOR LoadedReviews ;

Create Table dbo.RSchools (
	SchoolId int not null identity(1,1) primary key Nonclustered,
	SchoolName nvarchar(100) );

Alter Table dbo.RSchools
  Add Constraint Unique_SchoolName Unique Nonclustered (SchoolName);

GO

select Reverse(Stuff(Reverse(','), 1, 1, '')) ;


