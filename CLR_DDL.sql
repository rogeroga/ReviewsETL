--
-- DDL SQL script to manage the CLR functions used to load, extract 
-- the dev bootcamp school reviews data
--


Use [Sabio]
go

-- Enable executon of CLR functions in SQL server
-- 
EXEC sys.sp_configure 'show advanced options', 1
go
RECONFIGURE
go

EXEC sys.sp_configure 'clr enabled', 1
go
RECONFIGURE
go

ALTER DATABASE [Sabio] SET TRUSTWORTHY ON;
go

 
-- Drop Assembly
--
drop assembly Sabio
go

-- Install the CLR functions assembly and DLL dependencies
--
create assembly Sabio authorization dbo
from 'C:\Users\roble\Documents\Sabio\BotClient\BotClient\bin\Release\BotClient.dll' 
with permission_set = unsafe
go

-------------
-- GetFiles
-------------

-- Drop Function
-- 
IF OBJECT_ID('GetFiles') IS NOT NULL
   DROP FUNCTION GetFiles
GO

-- Define external function
--
create function GetFiles(@dir nvarchar(1024))
returns table (
		Name nvarchar(MAX), 
		CreationTime datetime, 
		LastWriteTime datetime )
as external name [Sabio].[BotClient.TableFunctions].[GetFiles]
go

-- Test the CLR function
--
select * from GetFiles('.') where LastWriteTime > '2017-06-01'
go


-------------
-- GetReviews
-------------

-- Drop Function
-- 
IF OBJECT_ID('GetReviews') IS NOT NULL
   DROP FUNCTION GetReviews
GO

-- Define external function
--
create function GetReviews(@reviewHtml nvarchar(MAX))
returns table (
            ReviewId integer,
			ReviewDate smalldatetime, 
            ReviewTitle nvarchar(MAX),
            ReviewerName nvarchar(MAX),
            Review nvarchar(MAX),
            Response nvarchar(MAX),

            Campus nvarchar(MAX), 
            Course nvarchar(MAX), 
            DeepLinkPath nvarchar(MAX),
            DeepLinkTarget nvarchar(MAX),
            
            RateCurriculum float,
            RateInstructors float,
            RateJobAssistance float,
            RateOverallExperience float
			)
as external name [Sabio].[BotClient.TableFunctions].[GetReviews]
go


-- Test the CLR function
--
select * from GetReviews('') 
go


declare @ReviewHtml nvarchar(MAX);

select TOP(1)
    @ReviewHtml = Input.[ReviewsHtml]
from
    [Sabio].[dbo].[Input] Input


select * from GetReviews(@ReviewHtml);

go
