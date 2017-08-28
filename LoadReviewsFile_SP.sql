--
-- SQL script to define the stored procedure to load, parse and extract review input files 
--

Use [Sabio]
Go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ---------------
-- Drop Procedure
-- ---------------
IF OBJECT_ID('LoadReviewsFile') IS NOT NULL
   Drop Procedure dbo.LoadReviewsFile
Go

-- ----------------------------------------------------------------------------------------
-- Description:	Procedure to load and parse an input file and extract 
-- the individual review records
-- -----------------------------------------------------------------------------------------
Create Procedure LoadReviewsFile ( @InputFile NVarChar(MAX), @ReceivedTime datetime)
As 
Begin
	-- Check if the input file was already loaded
	--
	IF EXISTS ( Select FileLogID From FileLog Where FileName = @InputFile )
		RETURN 1

	-- Declare local variables
	--
	Declare @Result int
	Declare @NewFileLogId int
	Declare @SchoolId int = 0
	
	-- Process a new file by creating a record in the FileLog table with status of no completed yet
	-- Obtain the new FileLogId primary key	
	Declare @OutputTbl Table (Id int)
	
	Insert into [dbo].[FileLog] ([FileName], [ProcessedDate], [Status], [ReceivedTime])
		Output Inserted.FileLogId into @OutputTbl(Id)
		Values (@InputFile, GetDate(), 0, @ReceivedTime)

	Select @NewFileLogId = Id From @OutputTbl 

	-- Dynamic SQL script to import the reviews file directly into the Stage table
	--
	Declare @Sql_String nvarchar(max) = 
		N'INSERT INTO [dbo].[Stage] (FileLogId, SchoolId, SchoolName, Url, RatingCount, Rating, RatingContent, ReviewsHtml, CurrentUrl, Error)
			SELECT ' + Convert(varchar(10), @NewFileLogId) + ',' + Convert(varchar(10), @SchoolId) + ', [SchoolName], [Url], [RatingCount], [Rating], [RatingContent], [ReviewsHtml], [CurrentUrl], [Error] 
			FROM OPENROWSET (BULK ' + Quotename(@InputFile, nchar(39)) + ', SINGLE_CLOB) as j
			CROSS APPLY OPENJSON(BulkColumn, ''$.rows'')
			WITH ( 
				SchoolName varchar(MAX) ''$[1]'',
				Url varchar(MAX) ''$[2]'',
				RatingCount varchar(MAX) ''$[3]'',
				Rating varchar(MAX) ''$[4]'',
				RatingContent varchar(200) ''$[5]'',
				ReviewsHtml varchar(MAX) ''$[6]'',
				CurrentUrl varchar(MAX) ''$[7]'',
				Error varchar(MAX) ''$[8]''
			)'
	
	-- Execute it to load the new input file into the Stage table and split Json content into columns
	--
	EXECUTE sp_executesql @Sql_String

    If @@ERROR <> 0 GoTo ErrorHandler

	-- Extract reviews by parsing review html content and creating individual review records
	--
	Declare @LoopCounter INT, 
			@MaxId INT, 
			@SchoolName nvarchar(MAX),
			@ReviewHtml nvarchar(MAX);

	Select @LoopCounter = Min(StageId), @MaxId = Max(StageId)
		From [dbo].[Stage]
		Where FileLogId = @NewFileLogId
 
	WHILE ( @LoopCounter IS NOT NULL AND @LoopCounter <= @MaxId )
	BEGIN
		SELECT @ReviewHtml = ReviewsHtml,
			   @SchoolName = SchoolName
		FROM [dbo].[Stage]
		WHERE FileLogId = @NewFileLogId AND StageId = @LoopCounter

		-- Check if the school already exists, if not insert it
		-- 
		SELECT @SchoolId = SchoolId FROM [dbo].[Schools] WHERE SchoolName = @SchoolName 
		IF @SchoolId IS NULL
			Begin
				Insert into [dbo].[Schools] ([SchoolName])
					Output Inserted.SchoolId into @OutputTbl(Id)
					Values ( @SchoolName )

				Select @SchoolId = Id From @OutputTbl
			End

		-- Extract and parse the individual reviews
		--
		INSERT INTO [dbo].[ReviewsLog] (StageId, FileLogId, SchoolId, ReviewId, ReviewDate, ReviewTitle, ReviewerName, Review, Response, 
						Campus, Course, DeepLinkPath, DeepLinkTarget, RateCurriculum, RateInstructors, RateJobAssistance, RateOverallExperience)
			SELECT @LoopCounter, @NewFileLogId, @SchoolId, * FROM GetReviews(@ReviewHtml)

		SET @LoopCounter = @LoopCounter + 1
	END

	If @@ERROR <> 0 GoTo ErrorHandler

	-- Set success status to the file just processed
	--
	Update [dbo].[FileLog] Set Status = 1 
		Where FileLogId = @NewFileLogId

    Set NoCount OFF
    Return (0)

ErrorHandler:
    Return (@@ERROR)

End

GO
