# Changelog

## TODO:
- Clean up all the lints, warnings

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