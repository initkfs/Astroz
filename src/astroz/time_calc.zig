const std = @import("std");
const math = std.math;

const geoDirection = @import("geo/direction.zig");
const dtCalc = @import("time/astro_date_calc.zig");
const julCalc = @import("time/julian_date_calc.zig");
const dt = @import("time/astro_local_datetime.zig");

pub fn lstToGst(comptime FloatType: type, lst: FloatType, longitude: FloatType, longitudePosition: geoDirection.CardinalDirection) FloatType {
    const longitudeDiff: FloatType = longitude / 15;
    var result: FloatType = lst;
    if (longitudePosition == geoDirection.CardinalDirection.west) {
        result += longitudeDiff;
    } else if (longitudePosition == geoDirection.CardinalDirection.east) {
        result -= longitudeDiff;
    }

    if (result < 0) {
        result += 24;
    } else if (result > 24) {
        result -= 24;
    }
    return result;
}

pub fn gstToLst(comptime IntType: type, comptime FloatType: type, time: dt.AstroLocalTime, longitude: FloatType, longitudeDirection: geoDirection.CardinalDirection) FloatType {
    const hoursForm: FloatType = dtCalc.timeToDecimalHours(time);
    const resultGst: FloatType = gstToLst(IntType, FloatType, hoursForm, longitude, longitudeDirection);
    return resultGst;
}

pub fn gstHoursToLst(comptime IntType: type, comptime FloatType: type, hoursForm: FloatType, longitude: FloatType, longitudeDirection: geoDirection.CardinalDirection) FloatType {
    var longitudeForCalc: FloatType = longitude;
    if (longitudeDirection == geoDirection.CardinalDirection.west) {
        longitudeForCalc = -longitudeForCalc;
    }

    const longitudeHours: FloatType = longitudeForCalc / 15.0;
    const lstHours: FloatType = dtCalc.fixHour(IntType, FloatType, hoursForm + longitudeHours);
    return lstHours;
}

pub fn gstToLstTime(comptime IntType: type, comptime FloatType: type, time: dt.AstroLocalTime, longitude: FloatType, longitudeDirection: geoDirection.CardinalDirection) dt.AstroLocalTime {
    const hoursForm: FloatType = gstToLst(IntType, FloatType, time, longitude, longitudeDirection);
    const timeForm: dt.AstroLocalTime = dtCalc.hoursToTime(IntType, FloatType, hoursForm);
    return timeForm;
}

pub fn utToGst(comptime IntType: type, comptime FloatType: type, date: dt.AstroLocalTime) FloatType {
    const jd: FloatType = julCalc.gregorianToJulianJD(IntType, FloatType, dt);
    const dayDiff: FloatType = (jd - 2451545.0) / 36525.0;
    var t0: FloatType = dtCalc.fixHour(IntType, FloatType, (6.697374558 + (2400.051336 * dayDiff) + (0.000025862 * math.pow(FloatType, dayDiff, 2))));
    if (t0 < 0) {
        t0 += 24;
    }

    var utHours: FloatType = dtCalc.timeToDecimalHours(IntType, FloatType, .{ .hour = date.hour, .minute = date.minute, .second = date.second });
    utHours = utHours * 1.002737909;

    var gstTime: FloatType = dtCalc.fixHour(IntType, FloatType, t0 + utHours);
    if (gstTime < 0) {
        gstTime += 24;
    }

    return gstTime;
}

pub fn gstToUt(comptime IntType: type, comptime FloatType: type, date: dt.AstroLocalDateTime, gstHours: FloatType) FloatType {
    const jd: FloatType = julCalc.gregorianToJulianJD(IntType, FloatType, date);
    const dayDiff: FloatType = (jd - 2451545.0) / 36525.0;
    const t0: FloatType = dtCalc.fixHour(IntType, FloatType, (6.697374558 + (2400.051336 * dayDiff) + (0.000025862 * math.pow(FloatType, dayDiff, 2))));
    const subGst: FloatType = dtCalc.fixHour(IntType, FloatType, gstHours - t0);
    const utHours: FloatType = subGst * 0.9972695663;

    return utHours;
}
