-- -----------------------------------------------------------------------------------------------
-- Daily job to execute the procedure to parse received files, extract and load the reviews in it
-- -----------------------------------------------------------------------------------------------

Use [Outcomes]
Go

Declare @FileTbl Table (Id int not null identity(1,1) primary key,
	Name nvarchar(MAX) not null,
	CreationTime DateTime not null,
	LastWriteTime DateTime not null) ;

-- Get all the filenames in the drop directory that have not been processed yet 
--
Insert into @FileTbl
  	Select * 
	From GetFiles(N'F:\Google Drive\dexio') 

-- 	From GetFiles(N'C:\Users\DBDeveloper\Google Drive\WebBot') 
--
	Where CHARINDEX(N'.json', Name) > 0
		AND Name Not In (
			SELECT FileName FROM dbo.FileLog Where Status = 1
		)
	Order by LastWriteTime asc ;

Declare @LoopCounter int, 
	@MaxId int, 
	@ReceivedTime datetime,
	@FileName nvarchar(MAX);

Select @LoopCounter = Min(Id), @MaxId = Max(Id)
	From @FileTbl
 
-- Process the new files
-- 
WHILE ( @LoopCounter IS NOT NULL AND @LoopCounter <= @MaxId )
BEGIN
	SELECT @FileName = [Name],
			@ReceivedTime = [LastWriteTime]
	From @FileTbl
	WHERE Id = @LoopCounter

	EXEC [dbo].[LoadReviewsFile] @FileName, @ReceivedTime

	SET @LoopCounter = @LoopCounter + 1
END

GO
