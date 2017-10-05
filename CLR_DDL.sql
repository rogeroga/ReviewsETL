-- -----------------------------------------------------------------------------------------------
-- DDL SQL script to manage the CLR functions used to load, extract 
-- the dev bootcamp school reviews data
-- -----------------------------------------------------------------------------------------------

Use [Outcomes]
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
Drop Assembly Sabio
Go

-- Install the CLR functions assembly and DLL dependencies
--
Create Assembly Sabio Authorization dbo
From 'C:\Users\roble\Documents\Sabio\BotClient\BotClient\bin\Release\BotClient.dll' 
With permission_set = unsafe
Go

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
Create function GetFiles(@dir nvarchar(1024))
Returns table (
		Name nvarchar(MAX), 
		CreationTime datetime, 
		LastWriteTime datetime )
as external name [Sabio].[BotClient.TableFunctions].[GetFiles]
Go

-- Test the newly defined CLR function
--
Select * from GetFiles('.') where LastWriteTime > '2017-06-01'
Go

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
Create function GetReviews(@reviewHtml nvarchar(MAX))
Returns table (
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
As external name [Sabio].[BotClient.TableFunctions].[GetReviews]
Go


-- Test the newly defined CLR function
--
Select * from GetReviews('') 
Go


Declare @ReviewHtml nvarchar(MAX);

Select TOP(1)
    @ReviewHtml = Input.[ReviewsHtml]
From
	[Outcomes].[dbo].[Input] Input

Select * from GetReviews(@ReviewHtml);
Go
