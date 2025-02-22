-- -----------------------------------------------------------------------------------------------
-- Stored procedure to parse, extract and load scrape dev bootcamp school review input files 
-- -----------------------------------------------------------------------------------------------

Use [Outcomes]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ---------------
-- Drop Procedure
-- ---------------
IF OBJECT_ID('PerformReviewsAnalysis') IS NOT NULL
   Drop Procedure dbo.PerformReviewsAnalysis
GO

Create Function PerformAnalysis (@FileTbl As ReviewFileTableType READONLY)
Returns int as 
Begin


return 0;

End

GO


-- ----------------------------------------------------------------------------------------
-- Procedure to load and parse an input file and extract the individual review records
-- -----------------------------------------------------------------------------------------
Create Procedure PerformReviewsAnalysis
As 
Begin

	-- Truncate tables where the report results would be stored
	-- 
	Truncate table [dbo].[ReviewDifferences] ;
	Truncate table [dbo].[MissingReviews] ;

	-- Checks all schools 
	--
	Declare @FileTbl As ReviewFileTableType, 
			@ReviewsTbl As ReviewsTableType;

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
		@DeletedIds nvarchar(max),
		@NewSchool int,
		@Tmp int;

	-- Count all the reviews per file loaded for each school 
	--
	Insert into @FileTbl(SchoolId, FileLogId, TotalReviews)
		Select r.SchoolId, r.FileLogId, Count(r.ReviewId) TotalReviews 
		From dbo.ReviewsLog r inner join FileLog l on r.FileLogId = l.FileLogId
			Where 
				l.Enabled = 1
	--
	--			AND r.SchoolId = 133		-- Coding Bootcamp Praha
	--			AND r.SchoolId = 48			-- Codesmith
	--
				AND l.ReceivedTime BETWEEN DATEADD(MONTH,-12,GETDATE()) AND GETDATE()
		Group by r.SchoolId, r.FileLogId
		Order by r.SchoolId asc, r.FileLogId asc ;


	-- Get min and max Ids from the temporary table 
	--
	Select @LoopCounter = MIN(Id), 
		@MaxId = MAX(Id)
	From @FileTbl ;

	-- Flag used to break apart schools and display an initial list of review Ids
	--
	Set @NewSchool = 1;

	-- Main loop to go through all the results in the results table
	--
	WHILE ( @LoopCounter IS NOT NULL AND @LoopCounter <= @MaxId )
	BEGIN

		Select @SchoolId1 = SchoolId,
				@SchoolName1 = SchoolName,
				@TotReviews1 = TotalReviews,
				@FileLog1 = FileLogId
		From @FileTbl
		Where Id = @LoopCounter;

		-- A new school start? reset flags and 
		-- get a count of the very first file for such school
		--
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
						-- Get a comma separated list of ReviewIds
						--
						Select @AddedIds = [dbo].[GetList](@ReviewsTbl);

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
		WHILE ( @SchoolId2 IS NOT NULL 
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
						Select @AddedIds = [dbo].[GetList](@ReviewsTbl);

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

			END  -- While loop to compare results for the same school

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
								-- Get a comma separated list of ReviewIds
								--
								Select @DeletedIds = [dbo].[GetList](@ReviewsTbl);

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
 								From dbo.ReviewsLog
 								Where ReviewsLog.FileLogId = @FileLog1 AND ReviewsLog.SchoolId = @SchoolId1
 									AND ReviewsLog.ReviewId NOT IN (
 											Select ReviewId
 											From dbo.ReviewsLog
 											Where FileLogId = @FileLog2 AND SchoolId = @SchoolId2
 									);

					End
			End
		
	END  -- Main Loop


	-- Print results
	-- 
	Select [@FileTbl].[SchoolId] as 'School Id', 
		   [Schools].[SchoolName] as 'School Name', 
		   [@FileTbl].[FileLogId] as 'File Log Id', 
		   [FileLog].[ReceivedTime] as 'File Received Time', 
		   [@FileTbl].[TotalReviews] as 'Review Counts In File', 
		   [@FileTbl].[AddedReviewIds] as 'Addedd Review Ids (Detail)' , 
		   [@FileTbl].[DeletedReviewIds] as 'Deleted Review Ids (Detail)'
	From @FileTbl, [dbo].[FileLog], [dbo].[Schools] 
	Where [@FileTbl].[FileLogId] = [FileLog].[FileLogId]
		AND [@FileTbl].[SchoolId] = [Schools].SchoolId  
		Order by  [@FileTbl].[Id] ASC ;

End

GO
