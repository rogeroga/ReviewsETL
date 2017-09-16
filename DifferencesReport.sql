--- 
---  Process all the files loaded so far and do an analysis of all the reviews per school
---

Use [Sabio]
Go

-- Truncate table where the report results would be stored
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
		@DeletedIds nvarchar(max);

-- Count all the reviews per file loaded for each school 
--
Insert into @FileTbl(SchoolId, SchoolName, FileLogId, TotalReviews)
Select Schools.SchoolId, Schools.SchoolName, ReviewsLog.FileLogId, Count(*) TotalReviews 
From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
	Where Schools.SchoolId = 93 
	Group by Schools.SchoolId, Schools.SchoolName, ReviewsLog.FileLogId
	Order by Schools.SchoolId asc, ReviewsLog.FileLogId asc ;

-- Get min and max Ids from the temporary table 
--
Select @LoopCounter = MIN(Id), 
	   @MaxId = MAX(Id)
	From @FileTbl ;

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

		Set @NextId = @LoopCounter + 1;

		Select @SchoolId2 = SchoolId,
			   @SchoolName2 = SchoolName,
			   @TotReviews2 = TotalReviews,
			   @FileLog2 = FileLogId
		From @FileTbl
		Where Id = @NextId;

		-- Do an analysis of the the reviews for each school, making sure that they are in an ascending fashion  
		--
		While ( @SchoolName2 IS NOT NULL AND @NextId <= @MaxId AND @SchoolId1 = @SchoolId2 AND @TotReviews1 <= @TotReviews2 )
			Begin

				-- Get the missing reviews not found in FileLog2
				--
				Set @DeletedIds = NULL;
				Select @DeletedIds = COALESCE(@DeletedIds + ', ', '') + CAST(ReviewsLog.ReviewId AS nvarchar)
				 
--					CASE
--						WHEN @DeletedIds IS NULL THEN CONVERT(VarChar(20), ReviewsLog.ReviewId)
--						ELSE ', ' + CONVERT(VarChar(20), ReviewsLog.ReviewId)
--						WHEN @DeletedIds IS NULL THEN CAST(ReviewsLog.ReviewId AS nvarchar)
--						ELSE N', ' + CAST(ReviewsLog.ReviewId AS nvarchar)
--					END
 				From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = @SchoolId1
 				Where ReviewsLog.FileLogId = @FileLog1
 					AND ReviewsLog.ReviewId NOT IN 
						(
 							Select ReviewsLog.ReviewId
 							From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = @SchoolId2
 							Where ReviewsLog.FileLogId = @FileLog2
 						)
				Order by ReviewsLog.ReviewId asc ;

				-- Get the added reviews in FileLog2
				--
				Set @AddedIds = NULL;
				Select @AddedIds =
				COALESCE(@AddedIds + ', ', '') + CAST(ReviewsLog.ReviewId AS nvarchar)
--					CASE
--						WHEN @AddedIds IS NULL THEN CAST(ReviewsLog.ReviewId AS nvarchar)
--						ELSE N', ' + CAST(ReviewsLog.ReviewId AS nvarchar)
--					END
 				From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = @SchoolId2
 				Where ReviewsLog.FileLogId = @FileLog2
 					AND ReviewsLog.ReviewId NOT IN 
						(
 							Select ReviewsLog.ReviewId
 							From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = @SchoolId1
 							Where ReviewsLog.FileLogId = @FileLog1
 						)
				Order by ReviewsLog.ReviewId asc ;

				-- Update added and deleted values
				--
				Update @FileTbl
					Set AddedReviewIds = @AddedIds, 
						DeletedReviewIds = @DeletedIds
					-- Id = @NextId
					Where SchoolId = @SchoolId2 AND
						FileLogId = @FileLog2 ;

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

			End

		Set @LoopCounter = @NextId


		If ( @SchoolId1 <> @SchoolId2 )
			Begin
				Set @LoopCounter = @NextId
			End 
		Else
			Begin
				If ( @TotReviews1 > @TotReviews2 )
					Begin
						-- Print 'NOT Ok: ' + @SchoolName1 + ', ' + 
							--	' Total Reviews1: ' + CAST(@TotReviews1 AS VARCHAR) + ' Total Reviews2: ' + CAST(@TotReviews2 AS VARCHAR) +
							--	' File Log1: ' + CAST(@FileLog1 AS VARCHAR) + ' File Log2: ' + CAST(@FileLog2 AS VARCHAR) +
							--	' Diff: ' + CAST((@TotReviews1 - @TotReviews2)  AS VARCHAR)

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

						Set @LoopCounter = @NextId	 
					End
			End
		
	END  -- Main Loop


	-- Print results
	-- 
	Select * From @FileTbl 
	Order by Id ASC ;




















