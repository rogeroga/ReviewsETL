-- -----------------------------------------------------------------------------
-- Daily job to execute the procedure to load received files and extract the reviews in it
-- -----------------------------------------------------------------------------

Use [Sabio]
Go

Declare @FileTbl Table (Id int not null identity(1,1) primary key,
	Name nvarchar(MAX) not null,
	CreationTime DateTime not null,
	LastWriteTime DateTime not null) ;

Insert into @FileTbl
	Select * from GetFiles(N'C:\Users\roble\Google Drive\dexio') 
	Where CHARINDEX(N'.json', Name) > 0
	Order by LastWriteTime asc ;

Declare @LoopCounter int, 
	@MaxId int, 
	@ReceivedTime datetime,
	@FileName nvarchar(MAX);

Select @LoopCounter = Min(Id), @MaxId = Max(Id)
	From @FileTbl
 
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
