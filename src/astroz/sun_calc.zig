const std = @import("std");
const math = std.math;

const angleCalc = @import("angle/angle_deg_calc.zig");
const geoDirect = @import("geo/direction.zig");
const dateTime = @import("time/astro_local_datetime.zig");
const dateTimeCalc = @import("time/astro_date_calc.zig");
const timeCalc = @import("time_calc.zig");
const julianDateTimeCalc = @import("time/julian_date_calc.zig");
const eclipticCoords = @import("coordinate/ecliptic/geocentric_ecliptic_coordinates.zig");
const equatorialCoords = @import("coordinate/equatorial/equatorial_coordinates.zig");
const coordsCalc = @import("coordinate_calc.zig");

pub fn SunData(comptime FloatType: type) type {
    return struct {
        meanLongitudeDeg: FloatType = 0,
        meanAnomalyDeg: FloatType = 0,
        geocentricEclipticCoords: eclipticCoords.GeocentricEclipticCoordinates(FloatType),
    };
}

pub fn SunRiseSet(comptime IntType: type) type {
    return struct {
        sunrise: dateTime.AstroLocalTime(IntType),
        sunset: dateTime.AstroLocalTime(IntType),
    };
}

pub fn LocalSiderealRiseSet(comptime FloatType: type) type {
    return struct {
        sunrise: FloatType,
        sunset: FloatType,
    };
}

pub fn position(comptime IntType: type, comptime FloatType: type, date: dateTime.AstroLocalDateTime(IntType)) SunData(FloatType) {
    //https://en.wikipedia.org/wiki/Position_of_the_Sun#cite_note-3
    //dates between 1950 and 2050.
    const jd: FloatType = julianDateTimeCalc.gregorianToJulianJD(IntType, FloatType, date);
    const numberOfDays: FloatType = jd - 2451545.0;
    const meanLongitudeDegValue: FloatType = angleCalc.toFullCircleDeg(FloatType, 280.460 + 0.9856474 * numberOfDays);
    const meanAnomalyDegValue = angleCalc.toFullCircleDeg(FloatType, @mod(357.528 + 0.9856003 * numberOfDays, 360.0));

    const eclipticLongitude: FloatType = meanLongitudeDegValue + 1.915 * math.sin(angleCalc.degToRadians(FloatType, meanAnomalyDegValue)) + 0.020 * math.sin(angleCalc.degToRadians(FloatType, meanAnomalyDegValue) * 2);

    const astroDistance: FloatType = 1.00014 - (0.01671 * math.cos(angleCalc.degToRadians(FloatType, meanAnomalyDegValue))) - (0.00014 * math.cos(angleCalc.degToRadians(FloatType, meanAnomalyDegValue) * 2));

    return .{ .meanLongitudeDeg = meanLongitudeDegValue, .meanAnomalyDeg = meanAnomalyDegValue, .geocentricEclipticCoords = .{
        .longitudeDeg = eclipticLongitude,
        .latitudeDeg = 0,
        .distanceAstroUnits = astroDistance,
    } };
}

pub fn calculateSunRiseSet(comptime IntType: type, comptime FloatType: type, now: dateTime.AstroLocalDateTime(IntType), longitude: FloatType, latitude: FloatType, longitudePosision: geoDirect.CardinalDirection) SunRiseSet(IntType) {

    //TODO or minute == 1?
    const midnight: dateTime.AstroLocalDateTime(IntType) = .{ .year = now.year, .month = now.month, .day = now.day };

    const sunData: SunData(FloatType) = position(IntType, FloatType, midnight);
    //const sunLongitude: FloatType = sunData.geocentricEclipticCoords.longitudeDeg;

    const equatorial: equatorialCoords.EquatorialCoordinates(FloatType) = coordsCalc.toEquatorial(IntType, FloatType, midnight, sunData.geocentricEclipticCoords);

    const rightAscension: FloatType = equatorial.rightAscension.hours;
    const declination: FloatType = equatorial.declination;

    //TODO correct add day. Check one day or 12 hours?
    const nextDate: dateTime.AstroLocalDateTime(IntType) = .{ .year = midnight.year, .month = midnight.month, .day = midnight.day + 1, .hour = midnight.hour, .minute = midnight.minute, .second = midnight.second };

    const newPosition: SunData(FloatType) = position(IntType, FloatType, nextDate);

    const newEquatorialCoords: equatorialCoords.EquatorialCoordinates(FloatType) = coordsCalc.toEquatorial(IntType, FloatType, nextDate, newPosition.geocentricEclipticCoords);

    const newRightAscensionHours: FloatType = newEquatorialCoords.rightAscension.hours;
    const newDeclination: FloatType = newEquatorialCoords.declination;

    const riseSet1: LocalSiderealRiseSet(FloatType) = calculateLocalSiderialTime(FloatType, latitude, rightAscension, declination);
    const riseSet2: LocalSiderealRiseSet(FloatType) = calculateLocalSiderialTime(FloatType, latitude, newRightAscensionHours, newDeclination);

    var GST1r: FloatType = timeCalc.lstToGst(FloatType, riseSet1.sunrise, longitude, longitudePosision);
    var GST1s: FloatType = timeCalc.lstToGst(FloatType, riseSet1.sunset, longitude, longitudePosision);
    var GST2r: FloatType = timeCalc.lstToGst(FloatType, riseSet2.sunrise, longitude, longitudePosision);
    var GST2s: FloatType = timeCalc.lstToGst(FloatType, riseSet2.sunset, longitude, longitudePosision);

    //TODO or minute == 0?
    const t00: FloatType = timeCalc.utToGst(IntType, FloatType, midnight);

    var longitudeFort001: FloatType = longitude;
    if (longitudePosision == geoDirect.CardinalDirection.west) {
        longitudeFort001 = -longitudeFort001;
    }

    var t001: FloatType = t00 - (longitudeFort001 / 15 * 1.002738);
    if (t001 < 0) {
        t001 += 24;
    }

    if (GST1r < (t001)) {
        GST1r += 24;
        GST2r += 24;
    }

    if (GST1s < t001) {
        GST1s += 24;
        GST2s += 24;
    }

    //TODO refine the abbreviation of the constant name
    const da: FloatType = 24.07;
    const resultGSTr: FloatType = (da * GST1r - t00 * (GST2r - GST1r)) / (da + GST1r - GST2r);
    const resultGSTs: FloatType = (da * GST1s - t00 * (GST2s - GST1s)) / (da + GST1s - GST2s);

    const averageDeclination: FloatType = (declination + newDeclination) / 2;
    const cosPhy: FloatType = angleCalc.radToDeg(FloatType, math.acos(math.sin(angleCalc.degToRadians(FloatType, latitude)))) / math.cos(angleCalc.degToRadians(FloatType, averageDeclination));

    const xForDeltaT: FloatType = 0.830725;
    const yForDeltaT: FloatType = angleCalc.radToDeg(FloatType, math.asin(math.sin(angleCalc.degToRadians(FloatType, xForDeltaT)))) / math.sin(angleCalc.degToRadians(FloatType, cosPhy));

    const deltaT: FloatType = 240 * yForDeltaT / math.cos(angleCalc.degToRadians(FloatType, averageDeclination));
    const deltaThour: FloatType = deltaT / 3600;

    const GSTs: FloatType = resultGSTs + deltaThour;
    const GSTr: FloatType = resultGSTr - deltaThour;

    const UTr: FloatType = timeCalc.gstToUt(IntType, FloatType, midnight, GSTr);
    const UTs: FloatType = timeCalc.gstToUt(IntType, FloatType, midnight, GSTs);

    const UTrTime: dateTime.AstroLocalTime(IntType) = dateTimeCalc.hoursToTime(IntType, FloatType, UTr);
    const UTsTime: dateTime.AstroLocalTime(IntType) = dateTimeCalc.hoursToTime(IntType, FloatType, UTs);

    return .{
        .sunrise = UTrTime,
        .sunset = UTsTime,
    };
}

fn calculateLocalSiderialTime(comptime FloatType: type, latitude: FloatType, rightAscensionHours: FloatType, declination: FloatType) LocalSiderealRiseSet(FloatType) {
    //const cosAr: FloatType = math.sin(angleCalc.degToRadians(FloatType, declination)) / math.cos(angleCalc.degToRadians(FloatType, latitude));
    //const Ar: FloatType = angleCalc.radToDeg(FloatType, math.acos(cosAr));
    //const As: FloatType = 360 - Ar;

    const latitudeRad:FloatType = angleCalc.degToRadians(FloatType, latitude);
    const declinationRad:FloatType = angleCalc.degToRadians(FloatType, declination);
    const acosH:FloatType = math.acos(-math.tan(latitudeRad) * math.tan(declinationRad));
    const quantityH: FloatType = (1.0 / 15.0) * angleCalc.radToDeg(FloatType, acosH);

    const LSTr: FloatType = dateTimeCalc.fixHour(FloatType, 24 + rightAscensionHours - quantityH);
    const LSTs: FloatType = dateTimeCalc.fixHour(FloatType, rightAscensionHours + quantityH);
    return .{
        .sunrise = LSTr,
        .sunset = LSTs,
    };
}

test "Test gregorian to julian" {
    const expect = std.testing.expect;
    const epsilon = math.epsilon(f64);

    const date = dateTime.AstroLocalDateTime(i64){ .year = 1980, .month = 7, .day = 27 };
    const result = position(i64, f64, date);
    try expect(math.approxEqRel(f64, result.meanAnomalyDeg, 202.22987075000037, epsilon));
    try expect(math.approxEqRel(f64, result.meanLongitudeDeg, 124.82757850000053, epsilon));
    try expect(math.approxEqRel(f64, result.geocentricEclipticCoords.distanceAstroUnits, 1.0155080797699694, epsilon));
}

test "Test sunrise-sunset" {
    const expect = std.testing.expect;

    const date = dateTime.AstroLocalDateTime(i64){ .year = 2022, .month = 4, .day = 1 };
    const result = calculateSunRiseSet(i64, f64, date, 73, 40, geoDirect.CardinalDirection.west);
    try expect(result.sunrise.hour == 10 and result.sunrise.minute > 25 and result.sunrise.minute < 45);
    try expect(result.sunset.hour == 23 and result.sunset.minute > 5 and result.sunset.minute < 25);
}
