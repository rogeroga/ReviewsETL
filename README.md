# ReviewsETL

Project to load, parse and extract data from screen scraping files to a SQL database used to perform review analytics.

This project contains the SQL scripts that drive the overall process. 

The main process looks like this: 

A scheduled job runs daily to pickup the latest screen scraping JSON file dropped in a Google Drive location,
a 3rd party vendor generates the file after extracting the data from a public website.

The JSON file is initially loaded in a Stage table, after this the records are processed and one column that contains
HTML content is parsed by calling the SQL CLR functions, data is extracted and inserted in the ReviewsLog table.

After the stage data is processed, analytics reports are executed to communicate the latest results.

Here is the information for the files found here:

DDL.sql contains the database table defintions.

CLR_DDL.sql create the assembly and their CLR functions.

LoadReviewsFile_SP.sql stored procedure to load the daily screen scraping file.

ScheduledJob.sql SQL script that runs daily, calls the previous stored procedure to load all the pending files to process. 

DifferenceReport.sql SQL script to perform analytics on the school reviews data.
