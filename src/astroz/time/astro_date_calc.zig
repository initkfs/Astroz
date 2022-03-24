const std = @import("std");
const math = std.math;

const dt = @import("astro_local_datetime.zig");
const jlCalc = @import("julian_date_calc.zig");

//https://ru.wikipedia.org/wiki/Дельта_T
pub fn deltaT(comptime IntType: type, comptime FloatType: type, year: IntType) FloatType {
    //2005—2050
    const delta: FloatType = 62.92 + 0.32217 * (year - 2000) + 0.005589 * ((year - 2000) ^ 2);
    return delta;
}

pub fn hoursToTime(comptime IntType: type, comptime FloatType: type, hoursValue: FloatType) dt.AstroLocalTime {
    const hours: IntType = @floatToInt(IntType, hoursValue);
    const minsPart: FloatType = (hoursValue - @intToFloat(FloatType, hours)) * 60;
    const mins: IntType = @floatToInt(IntType, minsPart);
    const sec: IntType = @floatToInt(IntType, ((minsPart - @intToFloat(FloatType, mins)) * 60));
    return .{
        .hours = hours,
        .minute = mins,
        .second = sec,
    };
}

pub fn timeToDecimalHours(comptime IntType: type, comptime FloatType: type, time: dt.AstroLocalTime(IntType)) FloatType {
    const hours: IntType = time.hour;
    const hoursFromSec: FloatType = @intToFloat(FloatType, time.second) / 3600;
    const hoursFromMin: FloatType = @intToFloat(FloatType, time.minute) / 60;
    const result: FloatType = @intToFloat(FloatType, hours) + hoursFromMin + hoursFromSec;
    return result;
}

pub fn daysBetweenDate(comptime IntType: type, comptime FloatType: type, startDate: dt.AstroLocalDateTime, endDate: dt.AstroLocalDateTime) FloatType {
    //TODO check startDate  <= endDate
    const startJulianDt: FloatType = jlCalc.gregorianToJulianJD(IntType, FloatType, startDate);
    const endJuliadDt: FloatType = jlCalc.gregorianToJulianJD(IntType, FloatType, endDate);
    const dateDiff: FloatType = endJuliadDt - startJulianDt;
    return dateDiff;
}

pub fn fixHour(comptime FloatType: type, h: FloatType) FloatType {
    return h - 24.0 * math.floor(h / 24.0);
}
