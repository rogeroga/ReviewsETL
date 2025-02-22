
--------------------
-- Case of CodeSmith
--------------------

Use [Sabio]
Go


SELECT *
  FROM [Sabio].[dbo].[ReviewDifferences]
  order by differenceid, schoolid, FirstFileLogId ;


  SELECT * 
  FROM [Sabio].[dbo].[ReviewDifferences]
  where SchoolId = 93
  order by differenceid, schoolid, FirstFileLogId ;

   
  SELECT RevDiff.*, FileLog1.ReceivedTime, FileLog2.ReceivedTime, FileLog1.FileName, FileLog2.FileName
  FROM [Sabio].[dbo].[ReviewDifferences] as RevDiff 
	inner join [Sabio].[dbo].[FileLog] as FileLog1 on RevDiff.FirstFileLogId = FileLog1.FileLogId
	inner join [Sabio].[dbo].[FileLog] as FileLog2 on RevDiff.SecondFileLogId = FileLog2.FileLogId
  Where [SchoolId] in (93)
  order by differenceid, schoolid, FirstFileLogId ;

	select * 
	from [dbo].[ReviewsLog]
	where SchoolId = 93 and (FileLogId = 74 OR FileLogId = 75)
	order by FileLogId asc, ReviewId asc;


	select * from dbo.MissingReviews
	where DifferenceId = 36 
	order by ReviewId;

select * from 
(

	Select ReviewsLog.FileLogId, ReviewsLog.ReviewId, count(*) as Dups
		From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
		Where Schools.SchoolId = 93 
		Group by ReviewsLog.FileLogId, ReviewsLog.ReviewId
) as tmp
Where tmp.Dups > 1 ;



  Select top(20) Schools.SchoolId, Schools.SchoolName, Temp.TotalMissingReviews
  From (
	  SELECT [SchoolId], count(*) as TotalMissingReviews
	  FROM [Sabio].[dbo].[MissingReviews]
	  group by [SchoolId] ) as Temp inner join [Schools] on Temp.SchoolId = Schools.SchoolId	  
   Order by Temp.TotalMissingReviews desc	   

  go

  SELECT RevDiff.*
  FROM [Sabio].[dbo].[ReviewDifferences] as RevDiff 
  Where [SchoolId] in (43, 298, 211, 273, 249, 293, 133, 15, 161, 284)
  order by differenceid, schoolid, FirstFileLogId ;

   
  SELECT RevDiff.*, FileLog1.FileName, FileLog2.FileName
  FROM [Sabio].[dbo].[ReviewDifferences] as RevDiff 
	inner join [Sabio].[dbo].[FileLog] as FileLog1 on RevDiff.FirstFileLogId = FileLog1.FileLogId
	inner join [Sabio].[dbo].[FileLog] as FileLog2 on RevDiff.SecondFileLogId = FileLog2.FileLogId
  Where [SchoolId] in (43, 298, 211, 273, 249, 293, 133, 15, 161, 284)
  order by differenceid, schoolid, FirstFileLogId ;


--
-- Procedure to digg down into a particular school
--
Declare @FileTbl Table (Id int not null identity(1,1) primary key,
		SchoolId int,
		SchoolName nvarchar(MAX),
		FileLogId int,
		TotalReviews int,
		AddIds NVARCHAR(max),
	    DelIds NVARCHAR(max)
);

Declare	@ReviewDifferences Table (
		SchoolId int,
		FirstFileLogId int,
		SecondFileLogId int,
		CountFirstFile int,
		CountSecondFile int);


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
		@SchoolName1 nvarchar(MAX),
		@SchoolName2 nvarchar(MAX),
		@Results NVarChar(max)

Insert into @FileTbl
	Select Schools.SchoolId, Schools.SchoolName, ReviewsLog.FileLogId, count(*) TotalReviews 
	From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
	Where Schools.SchoolId = 93 
	Group by Schools.SchoolId, Schools.SchoolName, ReviewsLog.FileLogId
	Order by Schools.SchoolName asc, ReviewsLog.FileLogId asc ;

Select @LoopCounter = Min(Id), 
	   @MaxId = Max(Id)
	From @FileTbl ;

-- Main loop to process until the end of the table
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

		While ( @SchoolName2 IS NOT NULL AND @NextId <= @MaxId AND @SchoolName1 = @SchoolName2 AND @TotReviews1 <= @TotReviews2 )
			Begin
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

		If ( @NextId > @MaxId )
			Begin
				Set @LoopCounter = @NextId
			End
		Else
			Begin
				If ( @SchoolName1 <> @SchoolName2 )
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

								Insert into @ReviewDifferences (SchoolId, FirstFileLogId, CountFirstFile, SecondFileLogId, CountSecondFile)
									Output Inserted.DifferenceId into @OutputTbl(Id)
									Values(@SchoolId1, @FileLog1, @TotReviews1, @FileLog2, @TotReviews2);

								Select @DiffId = Id From @OutputTbl


								Select @Results = 
										CASE
											WHEN @results IS NULL THEN CONVERT(VarChar(20), ReviewsLog.ReviewId)
											ELSE ', ' + CONVERT( VarChar(20), ReviewsLog.ReviewId)
										END
 									From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
 									Where Schools.SchoolName = @SchoolName1 AND ReviewsLog.FileLogId = @FileLog1
 										AND ReviewsLog.ReviewId NOT IN (
 											Select ReviewsLog.ReviewId
 												From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
 												Where Schools.SchoolName = @SchoolName1 AND ReviewsLog.FileLogId = @FileLog2
 										)
									Order by ReviewsLog.ReviewId asc;

					

								Select @Results = 
										CASE
											WHEN @results IS NULL THEN CONVERT(VarChar(20), ReviewsLog.ReviewId)
											ELSE ', ' + CONVERT( VarChar(20), ReviewsLog.ReviewId)
										END
 									From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
 									Where Schools.SchoolName = @SchoolName1 AND ReviewsLog.FileLogId = @FileLog1
 										AND ReviewsLog.ReviewId NOT IN (
 											Select ReviewsLog.ReviewId
 												From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
 												Where Schools.SchoolName = @SchoolName1 AND ReviewsLog.FileLogId = @FileLog2
 										)
									Order by ReviewsLog.ReviewId asc;

-- 								Insert into [dbo].[MissingReviews] (DifferenceId, SchoolId, ReviewId, Review, RateCurriculum, RateInstructors, RateJobAssistance, RateOverallExperience)
-- 									Select @DiffId, @SchoolId1, ReviewsLog.ReviewId, ReviewsLog.Review, ReviewsLog.RateCurriculum, ReviewsLog.RateInstructors, ReviewsLog.RateJobAssistance, ReviewsLog.RateOverallExperience
-- 										From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
-- 										Where Schools.SchoolName = @SchoolName1 AND ReviewsLog.FileLogId = @FileLog1
-- 											AND ReviewsLog.ReviewId NOT IN (
-- 												Select ReviewsLog.ReviewId
-- 													From dbo.ReviewsLog inner join Schools on ReviewsLog.SchoolId = Schools.SchoolId
-- 													Where Schools.SchoolName = @SchoolName1 AND ReviewsLog.FileLogId = @FileLog2
-- 											);

								 
								Set @LoopCounter = @NextId
							End
					End
			End
		
	END

