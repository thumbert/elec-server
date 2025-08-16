# Changelog

## TODO:
- Clean up all the lints, warnings
- Zip the json files for lower disk usage.  For daily archives, keep one 
  zip file for a year worth of data.  
- Move ISONE Monthly Asset NCPC to DuckDB

# Release 2025-08-16
- Add extension method toHtml() to List<List<String>>

# Release 2025-08-03
- exclude 2025-07-24 from IESO 24h check.  They messed up again. 
  Do populate the missing hour with the average of the values for the hour previous and after.

# Release 2025-07-11
- Fix CT backlog ingestion.  They broke the file format again!

# Release 2025-06-23
- Add better help and examples to qplot. 

# Release 2025-06-21
- Fix Plotly traces in dacongestion.dart.

# Release 2025-06-18
- Revert Plotly.exportJs() to not use await, because it's not allowed.  

# Release 2025-06-15
- First release of qplot.  Let's see if this is as useful as I hope it will be.
- Modify Plotly.now() to launch the default browser if file path is not specified.
  Added an await in front of the js Plotly.newPlot() invocation.

# Release 2025-05-27
- Some work on HQ water data

# Release 2025-05-14
- Fix IESO data break on 5/1/2025.  They won't fix it.

# Release 2025-04-16
- Fix CT suppliers backlog, had some issues with division by zero

# Release 2025-04-06
- Change NYISO TCC clearing price archive constructor

## Release 2025-03-30
- Convert ISONE energy offers to json format and support DuckDB only

## Release 2025-03-28
- Fix MRA results file format break

## Release 2025-03-26
- Don't delete all documents from Mongo collections on archive.setup() method!  Bad design! 

## Release 2025-03-09
- Fix MRA results file format break

## Release 2025-02-28
- Deal with empty DA binding constraints file, failed on 2/27/2025 
- Don't export mailtrap in utils library

## Release 2025-02-20
- Some work on mailtrap

## Release 2025-02-12
- Make a simple mailtrap email client
- Fix masked isone rt energy offers yet again

## Release 2025-02-10
- Fix masked demand bids DuckDB enum

## Release 2025-02-08
- Add firstMonth/lastMonth to the MisReportArchive class to skip ingestion once 
  the reports have been retired.

## Release 2025-01-07
- Fix ISONE Monthly Asset NCPC files with no data for the entire month.  

## Release 2025-01-06
- Change IESO public urls

## Release 2024-12-18
- Stop pulling utility rates for Springfield, MA -- they are no longer published

## Release 2024-12-02
- Add a timeout to downloadUrl from lib_iso_express

## Release 2024-11-30
- Fix issue with Supplier backlog rates

## Release 2024-11-28
- Make sql/nrc_generation_status.sql to create DuckDB 

## Release 2024-11-26
- ISONE Wholesale Load Cost report publishes RTLO data that is sometimes a string. 

## Release 2024-10-28
- Escape checks for 2024-10-18 for IESO RT demand data.  It's incomplete. 

## Release 2024-10-23
- Download ISONE sevenday solar forecast with puppeteer or python. 

## Release 2024-09-22
- Add ISONE RT prices to a duckdb database.

## Release 2024-08-26
- Create a getStack() function for the energy offers using the DuckDb infra.  

## Release 2024-08-19
- Rename NyisoDaEnergyOfferArchive to NyisoEnergyOfferArchive as it contains both 
  the DAM and the HAM markets!

## Release 2024-08-14
- Create folder notes/sql/ to keep examples of queries, etc.  In particular, made 
  an example on how to extract MIS versions from a table in notes/sql/mis_version.sql
- Add functionality to lib/client/da_energy_offer.dart to use DuckDB output.  

## Release 2024-08-03
- Cleanup ISONE DA/RT energy offers DuckDB process

## Release 2024-08-02
- Update dependencies

## Release 2024-07-29
- Work on ISONE MRA capacity bid offers and results archive.  Put them 
  both in the same db. 
- Work on ISONE rt reserve price archive

## Release 2024-07-26
- More work on nyiso energy offers

## Release 2024-07-22
- More work on nyiso energy offers SQL queries

## Release 2024-07-16
- Added ISONE rt_reserve_prices archive.  Not done yet
- Worked on nyiso stack.  Create a query that constructs the stack.  

## Release 2024-07-10
- Export ISONE morning report, 7 day capacity report dbs
- Upload NYISO energy offers into DuckDb.  Experiment with some queries in lib/client/nyiso/energy_offers.sql

## Release 2024-07-04
- Small improvements to the ISONE DA and RT energy offers DuckDB 

## Release 2024-06-26
- Add ISONE MorningReport archive using DuckDb
- Add ISONE 7DayCapacity archive using DuckDb
- Add ISONE RT Energy Offers archive using DuckDb

## Release 2024-05-11
- Implement mra_capacity_bidoffer archive.  Started to experiment with DuckDb 

## Release 2024-03-11
- Add NormalTemperatureArchive, api, client
- Fix issue with ISONE DaCongestionCompactArchive because of gzipped storage introduced on 3/3.  
  Run your tests! 
- Export db_weather.dart  

## Release 2024-03-03
- In lib_mis_reports.dart, allow MIS reports to be gzipped. 
- Reworked ISONE hourly DA LMP archive to be gzipped and split by year 

## Release 2024-01-20
- Plotly.now names the html div with the filename to prevent conflicts if when 
  included into other html files.  

## Release 2024-01-09
- Fixed type bug in api_sd_rtload.

## Release 2024-01-06
- Add ISONE's RtSystemLoad5min data to Mongo.  Archive files are gzipped and split by year.  
  Looks cleaner.
- Add more demand data to the archive for ISONE and IESO  

## Release 2023-11-27
- Sort by month the API response from api/utilities/api_ct_supplier_backlog.dart

## Release 2023-11-24
- Add Isone historical behind the meter solar data to the DB, etc. 

## Release 2023-11-15
- Add a partition extension to an Iterable

## Release 2023-11-12
- Fix lints, bump dependencies up

## Release 2023-11-08
- Add ability to add eventHandlers for Plotly.exportJs 

## Release 2023-11-05
- Add historical CMP load data, expose API and Client

## Release 2023-10-15
- Got CT supplier backlog rates implemented (db, api, client).  Data from 2022-01.  
  Amazing how hard it is to publish correct data on the web (I'm looking at you, 
  energizect).

## Release 2023-10-12
- Fix corner case in DA energy offer priceQuantityOffers calculation.  Don't crash 
  if the unit is unavailable for the entire term. 

## Release 2023-10-02
- Correct the IESO tz location.  Add several more api points and methods to the client.

## Release 2023-10-01
- IESO work.  Archive the rt_zonal_demand and rt_generation.  
- Export db_ieso library

## Release 2023-09-28
- Add the Polygraph projects db and the CME settlement data to the bin/rebuild_mongo 
  script.
- Started work on CT supliers backlog archive. 

## Release 2023-09-27
- Change Plotly.now arguments, require a file.  Add Plotly.exportJs. 

## Release 2023-09-19
- .env variables capitalized.
- Add the Polygraph projects db and the CME settlement data to the bin/rebuild_mongo
  script.

## Release 2023-08-13
- Make API for polygraph projects.

## Release 2023-07-29
- Improved tests for cme data api and client.
- Moved the web documentation in web/apps/public folder for simple_web_server

## Release 2023-07-28
- Add cme data to the server api

## Release 2023-07-17
- Export files from the db folder

## Release 2023-07-10
- Archive the CME data every day.
- Minor lints

## Release 2023-07-03
- Fix minor bug in lib/api/api_masked_ids.dart.  Hardened up to not fail if some ids 
  don't exist.

## Release 2023-06-19
- Point FwdRes url for Summer23!
- Minor fixes to tests
- Fix CalculatorArchive dbConfig argument

## Release 2023-06-16
- Zip the daily cme text files

## Release 2023-06-12
- Recreate the mongo from scratch, bin/rebuild_mongo.dart
  
## Release 2023-06-05
- Fix change in ISONE masked Demand Bids json format.  Thanks ISO.

## Release 2023-05-31
- Bump lower version of sdk to 3.0.2
- Bump up packages

## Release 2023-05-29
- Make a CME settlements database.  Set up a job in bin/jobs/download_cme_files to archive 
  some settlement prices daily
- Bump the sdk upper limit to 4.0.0

## Release 2023-03-29
- Change signature of DaLmp client.  Take out the iso from the constructor

## Release 2023-02-24
- Be more lenient on Retail Offer types.  Don't panic if not one of the allowed offer types. 
Data is dirty and for informational purposes only.

## Release 2023-01-28
- Combine api_dalmp and api_rtlmp in one file, to abstract over the market.  Should 
  probably do the same thing for the client.
- 

## Release 2023-01-26
- Add rt_lmp_hourly for NYISO.  Get the api working and unify it with the one in ISONE.  
  Add tests. 
- Add api to get hourly prices for multiple ptids in columnar format
- Unify the api for price information to be 'isone/da', 'isone/rt' from 'dalmp', 'rtlmp'.  
  Will deprecate the existing routes in 2024-01-27
- Add a rtlmp client for this data similar to the existing dalmp client

## Release 2023-01-24
- Fix CT rates download.  I was downloading only the first page!  Duh.

## Release 2023-01-12
- Make sure dalmp prices are inserted in the db as doubles and not ints by some unhappy csv 
  reading.  It is requested by the dalmp client.  Added an explict conversion in the 
  `client/dalmp.dart`, `getHourlyLmp()` method.  Ideally, that shouldn't be needed.    
- 

## Release 2023-01-08
- Fix da_lmp_hourly to upload csv files if already downloaded.
- Make an example of using **actors** for uploading files in the db concurrently.  
  See `test/db//update_dbs_actors_test.dart` file.  A speedup of 5x was achieved when uploading 
  one month of DAM hourly price files for ISONE. 

## Release 2023-01-02
- Switch da_lmp_hourly in ISONE to the json webservices.  The public csv service is just not 
reliable enough.  Stop inserting the 'hourBeginning' field from the documents in the collection.  
It is not needed as all hours in the day are published so the info is redundant.  Save on storage 
too.  Modify da_congestion_compact to work with json files too
- Switch rt_lmp_hourly in ISONE to the json webservices


## Release 2022-12-14
- More work on retail offers.  Added MA residential offers.  Hope that the DB format has stabilized.

## Release 2022-12-09
- Add 'loadZone' to the retail suppliers offers API

## Release 2022-12-07
- Add a static method to RetailSuppliersOffers client to get the offers as of a given date

## Release 2022-12-05
- Create `retail_suppliers` db to store competitive suppliers offers.  
  Insert CT offers.  Create API and client.  

## Release 2022-11-17
- Add a method to get public auctionIds for ny tcc's 
- Update list of winter storms for NE

## Release 2022-10-31
- Extract names of most recent New England storms (not uploaded in the db)
- Fix ISONE zonal demand client, issues with the DST data

## Release 2022-10-23
- Add fuel mix for isone
- Track StJohns port activity
- Add archive for rt load nyiso and btm solar actuals
- Download TCC clearing prices programmatically using auctionId 

## Release 2022-10-03
- Fix api for isone zonal_demand, the documentation link, the server 
  binding

## 2.0.2 (released 2021-11-28)
- Improve forward_marks API and client.  Added a route to pull strip prices 
  in an efficient way (batch call to the DB and caching.)
- Switched to lints, applied dart fix

## 2.0.1 (released 2021-06-19)
- null-safety version stable

## 2.0.0 (released 2021-05-30)
- Move to null-safety

## 1.2.1 (released 2021-05-17)
- very little updates, again prepare for null safety migration

## 1.1.0 (released 2021-03-07)
- Draw a line in the sand and start preparing for null safety