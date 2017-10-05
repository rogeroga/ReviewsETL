----------
-- DDL Tests
----------

Use [Outcomes]
Go

insert into FileLog(FileName,ProcessedDate,Status)
values(N'20170714_04_daily_-_cr_schools_v1.json', GETDATE(), 0) 

insert into FileLog(FileName,ProcessedDate,Status)
values(N'20170715_04_daily_-_cr_schools_v1.json', GETDATE(), 0) 


declare @NewFileLogId int ;

insert into FileLog(FileName,ProcessedDate,Status)
-- output into  @NewFileLogId
values(N'20170715_04_daily_-_cr_schools_v1.json', GETDATE(), 0) ;

SELECT @NewFileLogId = SCOPE_IDENTITY()

print @NewFileLogId ;

GO

DECLARE @OutputTbl TABLE (ID INT) 
declare @NewFileLogId int 

insert into FileLog(FileName, ProcessedDate, Status)
	output Inserted.FileLogId into @OutputTbl(ID)
	values(N'20170715_04_daily_-_cr_schools_v1.json', GETDATE(), 0) 

 SELECT @NewFileLogId = ID
	from @OutputTbl 

 print @NewFileLogId 

GO

