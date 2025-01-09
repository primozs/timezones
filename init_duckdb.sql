install spatial;
load spatial;

CREATE TABLE time_zone (
        zone_name VARCHAR(35) NOT NULL,
        country_code VARCHAR(2) NOT NULL,
        abbreviation VARCHAR(6) NOT NULL,
        time_start BIGINT NOT NULL,
        gmt_offset INT NOT NULL,
        dst VARCHAR(1) NOT NULL
      );
COPY time_zone FROM 'time_zone.csv';

CREATE INDEX idx_zone_name ON time_zone (zone_name);
CREATE INDEX idx_time_start ON time_zone (time_start);

CREATE TABLE country (
        country_code VARCHAR(2) NULL,
        country_name VARCHAR(45) NULL
      );
COPY country FROM 'country.csv';

CREATE INDEX idx_country_code ON country (country_code);

CREATE TABLE tz_shapes AS SELECT * FROM ST_Read('combined-shapefile-with-oceans-1970.shp');
CREATE INDEX geom_idx ON tz_shapes USING RTREE (geom);

-- example
-- select tzid from tz.main.tz_shapes WHERE st_contains(geom,'POINT(14.5 46.5)'::GEOMETRY);
