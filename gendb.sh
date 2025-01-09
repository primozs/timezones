#!/bin/sh

mkdir -p data
cd data
wget https://github.com/evansiroky/timezone-boundary-builder/releases/download/2024b/timezones-with-oceans-1970.shapefile.zip
unzip ./timezones-with-oceans-1970.shapefile.zip
wget https://timezonedb.com/files/TimeZoneDB.csv.zip
unzip ./TimeZoneDB.csv.zip

# ogr2ogr -f GeoJSON combined-shapefile-with-oceans-1970.shp.json combined-shapefile-with-oceans-1970.shp
# tippecanoe -ae -n tz -l tz -z6 -o tz.pmtiles combined-shapefile-with-oceans-1970.shp.json

rm -rf tz.duckdb
duckdb tz.duckdb < ../init_duckdb.sql
