-- ======================================================================================
---  DDL to Create the table file types
-- =======================================================================================

Use [Outcomes]
GO

-- Table types
--
IF type_id('[dbo].[ReviewFileTableType]') IS NOT NULL
	Drop Type [dbo].[ReviewFileTableType];
GO

Create Type dbo.ReviewFileTableType As Table
 (                     
	Id int not null identity(1,1) primary key,
	SchoolId int,
	SchoolName nvarchar(max),
	FileLogId int,
	TotalReviews int,
	AddedReviewIds nvarchar(max),
	DeletedReviewIds nvarchar(max)
 );

IF type_id('[dbo].[ReviewsTableType]') IS NOT NULL
   Drop Type dbo.ReviewsTableType
GO

Create Type ReviewsTableType As Table
(
	Id int not null identity(1,1) primary key, 
	ReviewId int
);

GO
