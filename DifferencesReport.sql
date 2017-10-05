-- ======================================================================================
---  Process all the files loaded so far and do an analysis of all the reviews per school
-- =======================================================================================

Use [Outcomes]
Go

-- Truncate tables where the report results would be stored
-- 
Truncate table ReviewDifferences ;
Truncate table MissingReviews ;
Go

-- Process all the reviews
--
Declare @FileTbl Table (
	Id int not null identity(1,1) primary key,
	SchoolId int,
	SchoolName nvarchar(max),
	FileLogId int,
	TotalReviews int,
	AddedReviewIds nvarchar(max),
	DeletedReviewIds nvarchar(max)
);

Declare	@ReviewDifferences Table (
	SchoolId int,
	FirstFileLogId int,
	SecondFileLogId int,
	CountFirstFile int,
	CountSecondFile int) ;

Declare @OutputTbl Table (Id int) ;

Declare @ReviewsTbl Table (Id int not null identity(1,1) primary key, 
							ReviewId int) ;

Declare @LoopCounter int, 
	@MaxId int,
	@NextId int,
	@TotReviews1 int,
	@TotReviews2 int,
	@FileLog1 int,
	@FileLog2 int,
	@DiffId int,
	@SchoolId1 int,
	@SchoolId2 int,
	@SchoolName1 nvarchar(max),
	@SchoolName2 nvarchar(max),
	@AddedIds nvarchar(max),
	@DeletedIds nvarchar(max),
	@NewSchool int,
	@Tmp int;

-- Count all the reviews per file loaded for each school 
--
Insert into @FileTbl(SchoolId, SchoolName, FileLogId, TotalReviews)
	Select Schools.SchoolId, Schools.SchoolName, ReviewsLog.FileLogId, Count(*) TotalReviews 
	From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
--		Where Schools.SchoolId = 93 
		Group by Schools.SchoolId, Schools.SchoolName, ReviewsLog.FileLogId
		Order by Schools.SchoolId asc, ReviewsLog.FileLogId asc ;

-- Get min and max Ids from the temporary table 
--
Select @LoopCounter = MIN(Id), 
	@MaxId = MAX(Id)
From @FileTbl ;

-- Flag used to break apart schools and display an initial list of review Ids
--
Set @NewSchool = 1;

-- Main loop to go through the results captured in the temporary table
--
WHILE ( @LoopCounter IS NOT NULL AND @LoopCounter <= @MaxId )
BEGIN

	Select @SchoolId1 = SchoolId,
			@SchoolName1 = SchoolName,
			@TotReviews1 = TotalReviews,
			@FileLog1 = FileLogId
	From @FileTbl
	Where Id = @LoopCounter;

	If (@NewSchool = 1) 
		Begin
			Set @NewSchool = 0;

			Set @AddedIds = N'' ;
			Delete From @ReviewsTbl ;

			Insert into @ReviewsTbl(ReviewId)
				Select ReviewId  
 				From dbo.ReviewsLog 
 				Where FileLogId = @FileLog1 
					AND SchoolId = @SchoolId1
 				Order by ReviewId asc ;

			Select @Tmp = ( Select Count(1) From @ReviewsTbl );

			If ( @Tmp > 0 )
				Begin
					Select @AddedIds = (
							Select CAST(ReviewId AS nvarchar) + ', '
							From @ReviewsTbl
							FOR XML PATH(''), TYPE
						).value('.', 'nvarchar(max)') ;

					Select @AddedIds = Reverse(Stuff(Reverse(@AddedIds), 1, 2, ''));

					-- Update added and deleted values
					--
					Update @FileTbl
						Set AddedReviewIds = @AddedIds
						Where SchoolId = @SchoolId1 AND
							FileLogId = @FileLog1 ;
				End

		End

	Set @NextId = @LoopCounter + 1;

	Select @SchoolId2 = SchoolId,
			@SchoolName2 = SchoolName,
			@TotReviews2 = TotalReviews,
			@FileLog2 = FileLogId
	From @FileTbl
	Where Id = @NextId;

	-- Do an analysis of the the reviews for each school, making sure that they are in an ascending fashion  
	--
	WHILE ( @SchoolName2 IS NOT NULL 
				AND @NextId <= @MaxId 
					AND @SchoolId1 = @SchoolId2 
						AND @TotReviews1 <= @TotReviews2 )
		BEGIN

			-- Get the added review Ids
			--
			Set @AddedIds = N'' ;
			Delete From @ReviewsTbl ;

			Insert into @ReviewsTbl(ReviewId)
				Select ReviewId  
 				From dbo.ReviewsLog 
 				Where FileLogId = @FileLog2 
					AND SchoolId = @SchoolId2
 					AND ReviewId NOT IN 
						(
 							Select ReviewId
 							From dbo.ReviewsLog 
 							Where FileLogId = @FileLog1
								AND SchoolId = @SchoolId1
 						)
				Order by ReviewId asc ;

  			Select @Tmp = ( Select Count(1) From @ReviewsTbl );

			If ( @Tmp > 0 )
				Begin
					-- Get a comma separated list of ReviewIds
					--
					Select @AddedIds = (
							Select CAST(ReviewId AS nvarchar) + ', '
							From @ReviewsTbl
							FOR XML PATH(''), TYPE
						).value('.', 'nvarchar(max)') ;

					Select @AddedIds = Reverse(Stuff(Reverse(@AddedIds), 1, 2, ''));

					-- Update added and deleted values
					--
					Update @FileTbl
						Set AddedReviewIds = @AddedIds
						Where SchoolId = @SchoolId2 AND
							FileLogId = @FileLog2 ;
				End

			Set @SchoolId1 = @SchoolId2;
			Set @SchoolName1 = @SchoolName2;
			Set @TotReviews1 = @TotReviews2;
			Set @FileLog1 = @FileLog2;

			Set @NextId = @NextId + 1;

			Select @SchoolId2 = SchoolId,
					@SchoolName2 = SchoolName,
					@TotReviews2 = TotalReviews,
					@FileLog2 = FileLogId
			From @FileTbl
			Where Id = @NextId;

		END

	Set @LoopCounter = @NextId;

	If ( @SchoolId1 <> @SchoolId2 )
		Begin
			Set @NewSchool = 1;
		End 
	Else
		Begin
			If ( @TotReviews1 > @TotReviews2 )
				Begin
					-- Get the missing reviews not found in FileLog2
					--
					Set @DeletedIds = N'' ;
					Delete From @ReviewsTbl ;

					Insert into @ReviewsTbl(ReviewId)
						Select ReviewId  
 						From dbo.ReviewsLog 
 						Where FileLogId = @FileLog1
							AND SchoolId = @SchoolId1
 							AND ReviewId NOT IN 
								(
 									Select ReviewId
 									From dbo.ReviewsLog
 									Where FileLogId = @FileLog2
										AND SchoolId = @SchoolId2
 								)
						Order by ReviewId asc ;

  					Select @Tmp = ( Select Count(1) From @ReviewsTbl );

					If ( @Tmp > 0 )
						Begin

							Select @DeletedIds = (
									Select CAST(ReviewId AS nvarchar) + ', '
									From @ReviewsTbl
									FOR XML PATH(''), TYPE
								).value('.', 'nvarchar(max)') ;

							Select @DeletedIds = Reverse(Stuff(Reverse(@DeletedIds), 1, 2, ''));

							Update @FileTbl
								Set DeletedReviewIds = @DeletedIds
								Where SchoolId = @SchoolId2 AND
									FileLogId = @FileLog2 ;
						End

					-- Insert differences found
					--
					Insert into ReviewDifferences (SchoolId, FirstFileLogId, CountFirstFile, SecondFileLogId, CountSecondFile)
						Output Inserted.DifferenceId into @OutputTbl(Id)
						Values(@SchoolId1, @FileLog1, @TotReviews1, @FileLog2, @TotReviews2);

					Select @DiffId = Id From @OutputTbl

 					Insert into MissingReviews (DifferenceId, SchoolId, ReviewId, Review, RateCurriculum, RateInstructors, RateJobAssistance, RateOverallExperience)
 						Select @DiffId, @SchoolId1, ReviewsLog.ReviewId, ReviewsLog.Review, ReviewsLog.RateCurriculum, ReviewsLog.RateInstructors, ReviewsLog.RateJobAssistance, ReviewsLog.RateOverallExperience
 							From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
 							Where Schools.SchoolName = @SchoolName1 AND ReviewsLog.FileLogId = @FileLog1
 								AND ReviewsLog.ReviewId NOT IN (
 									Select ReviewsLog.ReviewId
 										From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
 										Where Schools.SchoolName = @SchoolName1 AND ReviewsLog.FileLogId = @FileLog2
 								);

				End
		End
		
END  -- Main Loop


-- Print results
-- 
Select [@FileTbl].[SchoolId], [Schools].[SchoolName], [@FileTbl].[FileLogId], [FileLog].[ReceivedTime], 
		[@FileTbl].[TotalReviews], [@FileTbl].[AddedReviewIds], [@FileTbl].[DeletedReviewIds]
From @FileTbl, [dbo].[FileLog], [dbo].[Schools] 
Where [@FileTbl].[FileLogId] = [FileLog].[FileLogId]
	AND [@FileTbl].[SchoolId] = [Schools].SchoolId  
	Order by  [@FileTbl].[Id] ASC ;


