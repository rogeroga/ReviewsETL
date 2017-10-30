-- ======================================================================================
---  Functions
-- =======================================================================================

Use [Outcomes]
GO

-- ---------------
-- Drop Function
-- ---------------
IF OBJECT_ID('GetList') IS NOT NULL
   Drop Function dbo.GetList
GO

Create Function GetList (@Reviews ReviewsTableType READONLY)
Returns nvarchar(MAX) as 
Begin

	Declare @Str nvarchar(MAX);

	Select @Str = (
			Select CAST(ReviewId AS nvarchar) + ', '
			From @Reviews
			FOR XML PATH(''), TYPE
		).value('.', 'nvarchar(max)') ;

	Select @Str = Reverse(Stuff(Reverse(@Str), 1, 2, ''));

	Return @Str ;

End 

GO