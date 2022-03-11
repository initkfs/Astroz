const std = @import("std");
const math = std.math;

const angleCalc = @import("angle/angle_deg_calc.zig");
const dateTime = @import("time/astro_local_datetime.zig");
const dateTimeCalc = @import("time/astro_date_calc.zig");
const julianDateTimeCalc = @import("time/julian_date_calc.zig");
const eclipticCoords = @import("coordinate/ecliptic/geocentric_ecliptic_coordinates.zig");

pub fn SunData(comptime FloatType: type) type {
    return struct {
        meanLongitudeDeg: FloatType = 0,
        meanAnomalyDeg: FloatType = 0,
        geocentricEclipticCoords: eclipticCoords.GeocentricEclipticCoordinates(FloatType),
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

    return .{ 
        .meanLongitudeDeg = meanLongitudeDegValue, 
        .meanAnomalyDeg = meanAnomalyDegValue, 
        .geocentricEclipticCoords = .{
        .longitudeDeg = eclipticLongitude,
        .latitudeDeg = 0,
        .distanceAstroUnits = astroDistance,
    } };
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