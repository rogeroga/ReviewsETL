--
-- Table and Index defintions for the analytics of dev bootcamp school reviews
--

Use [Sabio]
Go

----------
-- FileLog
----------
drop table FileLog;
create table FileLog (
	FileLogId int not null identity(1,1) primary key,
	FileName nvarchar(MAX) not null,
	ProcessedDate DateTime not null,
	Status int );

---------
-- Stage
---------
drop table Stage;
create table Stage (
	StageId int not null identity(1,1) primary key,
	FileLogId int not null,
	SchoolId int not null,

	SchoolName nvarchar(MAX),
	Url nvarchar(MAX),

	RatingCount nvarchar(MAX),
	Rating nvarchar(MAX),
	RatingContent nvarchar(MAX),
	ReviewsHtml nvarchar(MAX),
	CurrentUrl nvarchar(MAX),
	Error nvarchar(MAX) );

-------------
-- ReviewsLog
-------------
drop table ReviewsLog;
create table ReviewsLog (
	StageId int not null,
	FileLogId int not null,
	SchoolId int not null,

	ReviewId int not null,
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
	RateOverallExperience float );

Create Unique Nonclustered Index [reviewslogidx] On [dbo].[Reviewslog]
(
	[FileLogId] Asc,
	[StageId] Asc,
	[SchoolId] Asc,
	[ReviewId] Asc
) with (pad_index = Off, Statistics_norecompute = Off, Sort_in_tempdb = Off, Ignore_dup_key = Off, Drop_existing = Off, Online = Off, Allow_row_locks = On, Allow_page_locks = On) 
On [primary];

-------------
-- ReviewDifferences
-------------
drop table ReviewDifferences;
create table ReviewDifferences (DifferenceId int not null identity(1,1) primary key,
		SchoolId int,
		FirstFileLogId int,
		SecondFileLogId int,
		CountFirstFile int,
		CountSecondFile int);

-----------------
-- MissingReviews
-----------------
drop table MissingReviews;
create table MissingReviews (DifferenceId int,
		SchoolId int,
		ReviewId int,
		Review nvarchar(MAX),
		RateCurriculum float,
		RateInstructors float,
		RateJobAssistance float,
		RateOverallExperience float);

alter table MissingReviews
add constraint MissingReviews_ReviewDifferences_DifferenceId_fk
foreign key (DifferenceId) References ReviewDifferences (DifferenceId)

----------
-- Schools
----------
drop table Schools;
create table Schools (
	SchoolId int not null identity(1,1) primary key,
	SchoolName nvarchar(MAX) );

Go
