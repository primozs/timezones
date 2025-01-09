{.push raises: [].}
import std/strformat
import std/strutils
import std/times
import pkg/duckdb
import std/options

type TimeZone* = object
  db: string
  connection: DuckDBConn

type Country = object
  country_code*: string
  country_name*: string

type TimeZoneData = object
  country_code*: string
  country_name*: string
  zone_name*: string
  abbreviation*: string
  gmt_offset*: int

proc connectTzDb(name: string): DuckDBConn =
  try:
    let dbConn = connect(name)
    return dbConn
  except Exception as e:
    echo e.repr


proc initTimezone*(db: string): TimeZone =
  try:
    let dbConn = connectTzDb(db)
    dbConn.exec("install spatial")
    dbConn.exec("load spatial")

    result.db = db
    result.connection = dbConn
  except Exception as e:
    echo e.repr()


proc getTzFromPos*(tz: TimeZone, lon, lat: float): string =
  try:
    var timezone = ""
    let query = fmt"select tzid from tz.main.tz_shapes WHERE st_contains(geom,'POINT({lon} {lat})'::GEOMETRY);"
    for item in tz.connection.rows(query):
      timezone = item[0]
      return timezone
  except Exception as e:
    echo e.repr()


proc getCountryes*(tz: TimeZone): seq[Country] =
  try:
    for item in tz.connection.rows("select * from country"):
      let country = Country(country_code: item[0], country_name: item[1])
      result.add country
  except:
    result = @[]


proc getNowIsoString(): string =
  let t = now().utc
  result = t.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'")


proc toTzData(r: seq[string]): TimeZoneData =
  result.country_code = r[0]
  result.country_name = r[1]
  result.zone_name = r[2]
  result.abbreviation = r[3]
  try:
    result.gmt_offset = r[4].parseInt
  except Exception:
    echo "Error parsing Tzdata"


proc getTimeZoneDataByCountry*(
    tz: TimeZone,
    country_code: string = "",
    datetime: string = ""
  ): TimeZoneData =
  try:
    let dt = if datetime == "": getNowIsoString() else: datetime
    let query = fmt"""
       select
          z.country_code,
          c.country_name,
          z.zone_name,
          z.abbreviation,
          z.gmt_offset,
          z.dst
        from time_zone z
          left join country c on c.country_code = z.country_code
        where
          z.country_code == ?
          and z.time_start <= epoch(TIMESTAMP '{dt}')
        order by z.time_start desc
       limit 1;
    """
    # z.time_start <= epoch(now())
    var row: seq[string]
    for item in tz.connection.rows(query, country_code):
      row = item

    return toTzData(row)
  except Exception as e:
    echo e.repr()


proc getTimeZoneDataByName*(
    tz: TimeZone,
    zone_name: string = "",
    datetime: string = ""
  ): TimeZoneData =
  try:
    let dt = if datetime == "": getNowIsoString() else: datetime
    let query = fmt"""
       select
          z.country_code,
          c.country_name,
          z.zone_name,
          z.abbreviation,
          z.gmt_offset,
          z.dst
        from time_zone z
          left join country c on c.country_code = z.country_code
        where
          z.zone_name == ?
          and z.time_start <= epoch(TIMESTAMP '{dt}')
        order by z.time_start desc
       limit 1;
    """
    # z.time_start <= epoch(now())
    var row: seq[string]
    for item in tz.connection.rows(query, zone_name):
      row = item

    return toTzData(row)
  except Exception as e:
    echo e.repr()


proc getTzOffsetFromPos*(tz: TimeZone, lon, lat: float,
    datetime: string = ""): Option[int] =
  let name = tz.getTzFromPos(lon, lat)
  if name == "":
    return none(int)

  let dt = if datetime == "": getNowIsoString() else: datetime
  let tzR = tz.getTimeZoneDataByName(name, dt)
  return some(tzR.gmt_offset)


when isMainModule:
  let tz = initTimezone("data/tz.duckdb")
  assert tz.getTzFromPos(14.5, 46.5) == "Europe/Vienna"
  assert tz.getTzFromPos(14.5, 45.5) == "Europe/Belgrade"
  assert tz.getTzFromPos(-8.13, 39.05) == "Europe/Lisbon"

  let r1 = tz.getTimeZoneDataByName("Europe/Ljubljana")
  assert r1.country_name == "Slovenia"

  let r2 = tz.getTimeZoneDataByName("Europe/Ljubljana", "2024-12-09T10:22:14.467Z")
  assert r2.gmt_offset == 3600

  let r3 = tz.getTimeZoneDataByName("Europe/Ljubljana", "2024-07-09T10:22:14.467Z")
  assert r3.gmt_offset == 7200

  let r4 = tz.getTimeZoneDataByCountry("SI")
  assert r4.country_name == "Slovenia"

  let r5 = tz.getTimeZoneDataByCountry("SI", "2024-12-09T10:22:14.467Z")
  assert r5.gmt_offset == 3600

  let r6 = tz.getTimeZoneDataByCountry("SI", "2024-07-09T10:22:14.467Z")
  assert r6.gmt_offset == 7200

  let r7 = tz.getTzOffsetFromPos(14.5, 46.5, "2024-12-09T10:22:14.467Z")
  assert r7.get() == 3600

  let r8 = tz.getTzOffsetFromPos(14.5, 46.5, "2024-07-09T10:22:14.467Z")
  assert r8.get() == 7200

  let r9 = tz.getTzOffsetFromPos(-8.13, 39.05, "2024-12-09T10:22:14.467Z")
  assert r9.get() == 0

  let r10 = tz.getTzOffsetFromPos(-8.13, 39.05, "2024-07-09T10:22:14.467Z")
  assert r10.get() == 3600
