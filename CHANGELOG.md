# Changelog

## TODO:
- 

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