import std/options
import unittest

import timezones

suite "timezones tests":
  var tz: TimeZone

  setup:
    tz = initTimezone("data/tz.duckdb")

  test "get pos austria":
    check tz.getTzFromPos(14.5, 46.5) == "Europe/Vienna"

  test "get pos slovenia":
    check tz.getTzFromPos(14.5, 45.5) == "Europe/Belgrade"

  test "get pos portugal":
    check tz.getTzFromPos(-8.13, 39.05) == "Europe/Lisbon"

  test "get countries":
    check tz.getCountryes().len == 246

  test "get tz data Europe/Ljubljana datetime now":
    let r1 = tz.getTimeZoneDataByName("Europe/Ljubljana")
    check r1.country_name == "Slovenia"

  test "get tz data Europe/Ljubljana datetime winter":
    let r2 = tz.getTimeZoneDataByName("Europe/Ljubljana", "2024-12-09T10:22:14.467Z")
    check r2.gmt_offset == 3600

  test "get tz data Europe/Ljubljana datetime summer":
    let r3 = tz.getTimeZoneDataByName("Europe/Ljubljana", "2024-07-09T10:22:14.467Z")
    check r3.gmt_offset == 7200

  test "get tz data SI datetime now":
    let r4 = tz.getTimeZoneDataByCountry("SI")
    check r4.country_name == "Slovenia"

  test "get tz data SI datetime winter":
    let r5 = tz.getTimeZoneDataByCountry("SI", "2024-12-09T10:22:14.467Z")
    check r5.gmt_offset == 3600

  test "get tz data SI datetime summer":
    let r6 = tz.getTimeZoneDataByCountry("SI", "2024-07-09T10:22:14.467Z")
    check r6.gmt_offset == 7200

  test "get offset by pos SI winter":
    let r7 = tz.getTzOffsetFromPos(14.5, 46.5, "2024-12-09T10:22:14.467Z")
    check r7.get() == 3600

  test "get offset by pos SI summer":
    let r8 = tz.getTzOffsetFromPos(14.5, 46.5, "2024-07-09T10:22:14.467Z")
    check r8.get() == 7200

  test "get offset by pos PT winter":
    let r9 = tz.getTzOffsetFromPos(-8.13, 39.05, "2024-12-09T10:22:14.467Z")
    check r9.get() == 0

  test "get offset by pos PT summer":
    let r10 = tz.getTzOffsetFromPos(-8.13, 39.05, "2024-07-09T10:22:14.467Z")
    check r10.get() == 3600

