# Best Mongo schema for congestion data display

In New England there are about 1200 electrical nodes for which prices are 
published hourly.  In this note I explore some designs to display congestion 
data from all nodes on an html canvas (currently using Plotly.)

Premise: get congestion prices for all ptids for Cal19 and format 
the data for Plotly (create the plot traces). 

Data is stored in mongodb as one document per node per day.  Each document has a 
congestion array of 24 prices.  Same for LMPs and loss component.  One year of data 
has +400k documents.  To store +10 years of data, the size of the data becomes large.

The base api is of the form 
```dart
http://127.0.0.1:8080/dalmp/v1/hourly/congestion/ptid/4000/start/2019-01-01/end/2019-01-02
```
and returns a list of in this form
```dart
[
  {"hourBeginning":"2019-01-01 00:00:00.000-0500","congestion":0.02},
  {"hourBeginning":"2019-01-01 01:00:00.000-0500","congestion":0.01},
  ...
]
```

For reference, getting all ptids in a serial fashion for one year takes 72.5s.  
We should use this value as a baseline, to understand the improvements of 
other approaches relative to this. 

If I parallelize the code above, by sending all the ptids requests at once to the 
database and wait for them to finish, the execution time decreases to 52.8s.  For 
one month alone (Jan19), the execution takes 4.7s, which is the upper limit of 
what a user may be willing to wait.  Note this time doesn't include the reshaping 
of the data from a ```List<TimeSeries>``` into the Plotly traces.

There is room for improvement in both the data layout in the database and in  
the api call.  

As the focus is to display the congestion component only, we can optimize for 
that.  To help with retrieval, let's store the data in the db as one document 
for one day 
for all the nodes in the pool.  The congestion values could also benefit from 
compression.  The ISO publishes prices as decimals a with two digit 
precision.  The value zero is special because it occurs in a lot of 
hours.  For example, here is a frequency distribution of values sorted 
decreasingly for the year 2019.

Congestion Value | Frequency
---------------- | ---------
0.0              | 63%
0.01             |  8%
0.02             |  7%
0.03             |  5%
0.04             |  3%
0.05             |  2%

Remarkable that no congestion (values of zero) are a whopping 63% of total
entries.  This suggests that a run length encoding (rle) type compression for 
the most common values will reduce the storage volume significantly. 
I will use rle on the 0, 0.01, and 0.02 values only.  This should pay 
benefits in the http layer too, as less data will be transferred over the wire.

```dart
{
  'date': '2019-01-01',
  'ptids': [4000, 4001, ...],
  'congestion': [
    [0, 24],  // for 4000, one value for each hour of the day
    [0, 3, 0.1, 4, 0.21, 0.27, ...], // for 4001, 
    ...,
  ]
}.
```
In the example above, for node 4001, the value 0 is for the first 3 hours, 
0.1 for the next 4, followed by 0.21, 0.27, etc.  The api will return the data 
in the same format, which will require only minimal processing for Plotly.  

With this change in place the results have improved significantly.  
Retrieving the congestion for all nodes for an entire year now takes 2.9s 
and one month takes 0.3s. 



