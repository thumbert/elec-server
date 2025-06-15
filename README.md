# elec_server

A web server built using [Shelf](https://pub.dartlang.org/packages/shelf).

- For an example on how to use Actors for ingesting data, 
  see `test/db/update_dbs_actors_test.dart`.

- To serve the documentation using the [Static Web Server](https://static-web-server.net/) 
  start in the ~/Documents/apps directory
  static-web-server --host 127.0.0.1 --port 9000 --log-level info 
  navigate to http://127.0.0.1:9000/documentation.html and you should be able to see it


cp ~/Documents/repos/git/thumbert/rascal/html/docs/index.html ~/Software/Apps/public/docs   

```
duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/isone/ttc.duckdb';
SELECT hour_beginning, hq_phase2_import, ny_north_import, nb_import
FROM ttc.ttc_limits 
WHERE hour_beginning >= '2024-01-01'
AND hour_beginning < '2024-01-05'
ORDER BY hour_beginning;
" | qplot 
```
