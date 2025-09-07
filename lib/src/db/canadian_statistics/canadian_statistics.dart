

class CanadianStatisticsArchive {
  CanadianStatisticsArchive({required this.duckDbPath});

  late final String duckDbPath;


//   Map<String,TimeSeries<num>> dailyWaterLevel({List<String>? stationIds}) {
//     final conn = Connection(duckDbPath);

//     final query = '''
// SELECT strftime('%Y-%m-%d', hour_beginning) AS date,
//     station_id,
//     median(value) AS value
// FROM WaterLevel
// WHERE station_id != '1-7306'
// GROUP BY date, station_id
// ORDER BY station_id, date;
// ''';
//     final data = conn.fetchRows(query, (List row) => (date: Date.fromIsoString(row[0], location: UTC), stationId: row[1] as String, value: row[2] as num));

//     final groups = groupBy(data, (e) => e.stationId);
//     var res = <String,TimeSeries<num>>{};
//     for (String stationId in groups.keys) {
//       var values = groups[stationId]!;
//       res[stationId] = values.map((e) => IntervalTuple(e.date, e.value)).toTimeSeries();
//     }
//     return res;
//   }


//   TimeSeries<num> totalDailyWaterLevel() {
//     final conn = Connection(duckDbPath);

//     final result = conn.fetchRows('''
// SELECT strftime('%Y-%m-%d', hour_beginning) AS date, 
//        round(mean(value)) AS value
// FROM (
//     SELECT hour_beginning, 
//         sum(value) AS value
//     FROM WaterLevel
//     WHERE station_id != '1-7306'
//     GROUP BY hour_beginning
// )       
// GROUP BY date
// ORDER BY date;
// ''', (List row) => IntervalTuple<num>(Date.fromIsoString(row[0], location: UTC), row[1]));
//     return result.toTimeSeries();
//   }
}
