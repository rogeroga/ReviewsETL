-- ============================================================================
-- Tables and Index defintions for the analytics of dev bootcamp school reviews
-- ============================================================================

Use [Outcomes]
GO

-- ============================================================================
-- Config
-- ============================================================================
IF OBJECT_ID('dbo.Config', 'U') IS NOT NULL
  Drop Table dbo.Config ;
GO

Create Table dbo.Config (
	Id int not null identity(1,1) primary key nonclustered,
	ParameterName nvarchar(100) not null,
	ParameterValue nvarchar(MAX) not null,
	Enabled int not null);

Alter Table dbo.Config
  Add Constraint Unique_ParameterName Unique Nonclustered (ParameterName);

INSERT INTO dbo.Config                        
			(ParameterName, ParameterValue, Enabled)
     VALUES
           ('DEV_FILE_LOCATION',
            'C:\Users\roble\Google Drive\dexio',
            1);

INSERT INTO dbo.Config
           (ParameterName, ParameterValue, Enabled)
     VALUES
           ('PROD_FILE_LOCATION',
            'C:\Users\DBDeveloper\Google Drive\WebBot',
            1);
GO

-- ============================================================================
-- FileLog
-- ============================================================================
IF OBJECT_ID('dbo.FileLog', 'U') IS NOT NULL
  Drop Table dbo.FileLog ;
GO

Create Table dbo.FileLog (
	FileLogId int not null identity(1,1) primary key nonclustered,
	FileName nvarchar(MAX) not null,
	ProcessedDate DateTime not null,
	ReceivedTime DateTime not null,
	Status int );
GO

-- ============================================================================
-- Stage
-- ============================================================================
IF OBJECT_ID('dbo.Stage','U') IS NOT NULL
  Drop Table dbo.Stage ;
GO

Create Table dbo.Stage (
	StageId int not null identity(1,1) primary key nonclustered,
	FileLogId int not null,
	SchoolName nvarchar(MAX),

	Url nvarchar(MAX),
	RatingCount nvarchar(MAX),
	Rating nvarchar(MAX),
	RatingContent nvarchar(MAX),
	ReviewsHtml nvarchar(MAX),
	CurrentUrl nvarchar(MAX),
	Error nvarchar(MAX),
	LoadedReviews int default 0);
GO

-- ============================================================================
-- ReviewsLog
-- ============================================================================
IF OBJECT_ID('dbo.ReviewsLog','U') IS NOT NULL
  Drop Table dbo.ReviewsLog ;
GO

Create Table dbo.ReviewsLog (
	FileLogId int not null,
	StageId int not null,
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

Alter Table dbo.ReviewsLog
  Add Constraint Unique_ReviewId Unique Nonclustered (FileLogId, SchoolId, ReviewId);

GO

Create Unique Nonclustered Index [ReviewsLogIdx] On dbo.Reviewslog
(
	FileLogId Asc,
	StageId Asc,
	SchoolId Asc,
	ReviewId Asc
) with (pad_index = Off, Statistics_norecompute = Off, Sort_in_tempdb = Off, Ignore_dup_key = Off, Drop_existing = Off, Online = Off, Allow_row_locks = On, Allow_page_locks = On) 
On [primary];

GO

-- ============================================================================
-- Schools
-- ============================================================================
IF OBJECT_ID('dbo.Schools','U') IS NOT NULL
  Drop Table dbo.Schools ;
GO

Create Table dbo.Schools (
	SchoolId int not null identity(1,1) primary key nonclustered,
	SchoolName nvarchar(100) );

Alter Table dbo.Schools
  Add Constraint Unique_SchoolName Unique Nonclustered (SchoolName);

GO

-- ============================================================================
-- ReviewDifferences
-- ============================================================================
IF OBJECT_ID('dbo.ReviewDifferences','U') IS NOT NULL
  Drop Table dbo.ReviewDifferences ;
GO

Create Table ReviewDifferences (DifferenceId int not null identity(1,1) primary key nonclustered,
		SchoolId int,
		FirstFileLogId int,
		SecondFileLogId int,
		CountFirstFile int,
		CountSecondFile int);
GO

-- ============================================================================
-- MissingReviews
-- ============================================================================
IF OBJECT_ID('dbo.MissingReviews','U') IS NOT NULL
  Drop Table dbo.MissingReviews ;
GO

Create Table dbo.MissingReviews (DifferenceId int,
		SchoolId int,
		ReviewId int,
		Review nvarchar(MAX),
		RateCurriculum float,
		RateInstructors float,
		RateJobAssistance float,
		RateOverallExperience float);
GO
