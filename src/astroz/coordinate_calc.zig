const std = @import("std");
const math = std.math;

const angleCalc = @import("angle/angle_deg_calc.zig");
const dateTime = @import("time/astro_local_datetime.zig");
const julianDateTimeCalc = @import("time/julian_date_calc.zig");
const ecliptic = @import("coordinate/ecliptic/geocentric_ecliptic_coordinates.zig");
const equatorial = @import("coordinate/equatorial/equatorial_coordinates.zig");
const equatorialRA = @import("coordinate/equatorial/equatorial_right_ascension.zig");

const julianDateTimeCalc = @import("time/julian_date_calc.zig");

//TODO move to coordinate package after fix import from parent directories

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
