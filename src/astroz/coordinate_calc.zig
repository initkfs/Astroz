const std = @import("std");
const math = std.math;

const angleCalc = @import("angle/angle_deg_calc.zig");
const dateTime = @import("time/astro_local_datetime.zig");
const julianDateTimeCalc = @import("time/julian_date_calc.zig");
const ecliptic = @import("coordinate/ecliptic/geocentric_ecliptic_coordinates.zig");
const equatorial = @import("coordinate/equatorial/equatorial_coordinates.zig");
const equatorialRA = @import("coordinate/equatorial/equatorial_right_ascension.zig");
const timeCalc = @import("time_calc.zig");
const geoDirection = @import("geo/direction.zig");
const horizontal = @import("coordinate/horizontal/horizontal_coordinates.zig");

//TODO move to coordinate package after fix import from parent directories
pub fn rightAscensionToHourAngle(comptime IntType: type, FloatType: type, raDeg: FloatType, utcTime: dateTime.AstroLocalDateTime(IntType), longitude: FloatType, longitudeDirection: geoDirection.CardinalDirection) FloatType {
    const gst: FloatType = timeCalc.utToGst(IntType, FloatType, utcTime);
    const lst: FloatType = timeCalc.gstHoursToLst(FloatType, gst, longitude, longitudeDirection);
    const raHours: FloatType = rightAscensionToHours(FloatType, raDeg);
    var hourAngle: FloatType = lst - raHours;
    if (hourAngle < 24) {
        hourAngle += 24;
    }
    return hourAngle;
}

//TODO move to RA package
pub fn rightAscensionToHours(comptime FloatType: type, ra: FloatType) FloatType {
    return ra / 15.0;
}

pub fn hoursAngleToDeg(comptime FloatType: type, hourAngle: FloatType) FloatType {
    return hourAngle * 15.0;
}

pub fn toHorizontal(comptime IntType: type, FloatType: type, equatorialCoords: equatorial.EquatorialCoordinates(FloatType), utcTime: dateTime.AstroLocalDateTime(IntType), longitude: FloatType, longitudeDirection: geoDirection.CardinalDirection, latitude: FloatType) horizontal.HorizontalCoordinates(FloatType) {
    const declinationDeg: FloatType = equatorialCoords.declination;
    const hourAngle: FloatType = rightAscensionToHourAngle(IntType, FloatType, equatorialCoords.rightAscension.deg, utcTime, longitude, longitudeDirection);

    const hourAngleDeg: FloatType = hoursAngleToDeg(FloatType, hourAngle);

    const sinA: FloatType = math.sin(angleCalc.degToRadians(FloatType, declinationDeg)) * math.sin(angleCalc.degToRadians(FloatType, latitude)) + math.cos(angleCalc.degToRadians(FloatType, declinationDeg)) * math.cos(angleCalc.degToRadians(FloatType, latitude)) * math.cos(angleCalc.degToRadians(FloatType, hourAngleDeg));
    const altitude: FloatType = math.asin(sinA);
    const altitudeDeg: FloatType = angleCalc.toFullCircleNeg90To90Deg(FloatType, angleCalc.radToDeg(FloatType, altitude));

    const x: FloatType = math.sin(angleCalc.degToRadians(FloatType, declinationDeg)) - math.sin(angleCalc.degToRadians(FloatType, latitude)) * math.sin(angleCalc.degToRadians(FloatType, altitudeDeg));
    const y: FloatType = -math.cos(angleCalc.degToRadians(FloatType, declinationDeg)) * math.cos(angleCalc.degToRadians(FloatType, latitude)) * math.sin(angleCalc.degToRadians(FloatType, hourAngleDeg));

    const mustBeAzimuth: FloatType = math.atan2(FloatType, y, x);
    const azimuthDeg: FloatType = angleCalc.toFullCircleDeg(FloatType, angleCalc.radToDeg(FloatType, mustBeAzimuth));

    return .{
        .altitudeDeg = altitudeDeg,
        .azimuthDeg = azimuthDeg,
    };
}

pub fn toEquatorial(comptime IntType: type, FloatType: type, date: dateTime.AstroLocalDateTime(IntType), eclipticCoords: ecliptic.GeocentricEclipticCoordinates(FloatType)) equatorial.EquatorialCoordinates(FloatType) {
    const eclipticLongitude: FloatType = eclipticCoords.longitudeDeg;

    const meanObliquitySun: FloatType = calculateObliquityDeg(IntType, FloatType, date);

    const rightAscensionRad: FloatType = math.atan2(FloatType, math.cos(angleCalc.degToRadians(FloatType, meanObliquitySun)) * math.sin(angleCalc.degToRadians(FloatType, eclipticLongitude)), math.cos(angleCalc.degToRadians(FloatType, eclipticLongitude)));
    const declinationRad: FloatType = math.asin(math.sin(angleCalc.degToRadians(FloatType, meanObliquitySun)) * math.sin(angleCalc.degToRadians(FloatType, eclipticLongitude)));

    const rightAscensionDeg: FloatType = angleCalc.radToDeg(FloatType, rightAscensionRad);

    const rightAscensionHours: FloatType = rightAscensionDeg / 15;

    const rightAscension: equatorialRA.EquatorialRightAscension(FloatType) = .{ .deg = rightAscensionDeg, .hours = rightAscensionHours };

    const equatorialCoordinates: equatorial.EquatorialCoordinates(FloatType) = .{ .declination = angleCalc.radToDeg(FloatType, declinationRad), .rightAscension = rightAscension };
    return equatorialCoordinates;
}

//TODO move to sphere package
fn calculateObliquityDeg(comptime IntType: type, comptime FloatType: type, date: dateTime.AstroLocalDateTime(IntType)) FloatType {
    const jd: FloatType = julianDateTimeCalc.gregorianToJulianJD(IntType, FloatType, date);
    const n: FloatType = jd - julianDateTimeCalc.julianDaysEpoch2000;
    // obliquity eps of ecliptic:
    const eps: FloatType = 23.439 - 0.0000004 * n;
    return eps;
}

test "Test convert equatorial to horizontal" {
    const expect = std.testing.expect;

    const equatorialCoords = .{
        //28°13'08''
        .declination = 28.2189,
        .rightAscension = .{
            .deg = 150,
            .hours = 10,
        },
    };

    const horizontalCoords = toHorizontal(i64, f64, equatorialCoords, .{ .year = 2022, .month = 4, .day = 1, .hour = 18, .minute = 30 }, 71.0, geoDirection.CardinalDirection.west, 41.0);

    //TODO more precision
    try expect(@floatToInt(i64, horizontalCoords.azimuthDeg) == 54);
    try expect(@floatToInt(i64, horizontalCoords.altitudeDeg) == 3);
}
