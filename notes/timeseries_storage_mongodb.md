# Optimal timeseries storage for MongoDb

Here are some strategies I've used to store timeseries data into 
MongoDb and a discussion of the benefits/drawbacks associated with 
each strategy. 

## Hourly data

For hourly data if found that storing each hour as a document is 
an overkill.  What I usually do is, I group all hourly observations 
from one day, and store that as a document.  Something like this:
```dart
{
  'seriesId': 'series1',
  'date': 20220102,
  'variable1': <num>[...],  
  'variable2': <num>[...],
  ...
}
```
The collection indexes are ```['seriesId', 'date']``` and ```'date''```.   
All API calls are typically to get one series between a start/end date, 
or all series for a given date.  This is what it's done in the 
```db/isoexpress/da_lmp_hourly.dart``` file. 

Advantages of this formulation is that it allows you to reinsert each 
date separately.  Usually you insert all hours of the day at once.  
Partial data for only a few hours of the day works as long as you insert 
all the hours available for the day. 

Maybe you can denormalize the data even more by storing 
only one variable in the document, and making the seriesId reflect the 
variable name. 

## Daily data

A natural approach is to store each year as a document, so the document 
would look like 
```dart
{
  'seriesId': 'series1',
  'year': 2022,
  'value': <num>[...],  
  ...
}
```
This allows for a nice compact storage for an entire year as one document. 
If the updates come with a daily frequency, care must be taken to append to the 
```value``` list.  If there is a need to reinsert a part of the year, values 
need to be updated at the correct spot in the ```value``` list.



