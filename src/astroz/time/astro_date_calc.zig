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

pub fn hoursToTime(comptime IntType: type, comptime FloatType: type, hoursValue: FloatType) dt.AstroLocalTime(IntType) {
    const hours: IntType = @floatToInt(IntType, hoursValue);
    const minsPart: FloatType = (hoursValue - @intToFloat(FloatType, hours)) * 60;
    const mins: IntType = @floatToInt(IntType, minsPart);
    const sec: IntType = @floatToInt(IntType, ((minsPart - @intToFloat(FloatType, mins)) * 60));
    return .{
        .hour = hours,
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

pub fn daysBetweenDate(comptime IntType: type, comptime FloatType: type, startDate: dt.AstroLocalDateTime(IntType), endDate: dt.AstroLocalDateTime(IntType)) FloatType {
    //TODO check startDate  <= endDate
    const startJulianDt: FloatType = jlCalc.gregorianToJulianJD(IntType, FloatType, startDate);
    const endJuliadDt: FloatType = jlCalc.gregorianToJulianJD(IntType, FloatType, endDate);
    const dateDiff: FloatType = endJuliadDt - startJulianDt;
    return dateDiff;
}

pub fn fixHour(comptime FloatType: type, h: FloatType) FloatType {
    const hoursInDay:FloatType = 24.0;
    return h - hoursInDay * math.floor(h / hoursInDay);
}

test "Test hours to time" {
    const expect = std.testing.expect;

    const time0 = hoursToTime(i64, f64, 0);
    try expect(time0.hour == 0 and time0.minute == 0 and time0.second == 0);
    const time1 = hoursToTime(i64, f64, 1);
    try expect(time1.hour == 1 and time1.minute == 0 and time1.second == 0);
    const time2 = hoursToTime(i64, f64, 2.52);
    try expect(time2.hour == 2 and time2.minute == 31 and time2.second == 12);
}

test "Test time to hours" {
    const expect = std.testing.expect;
    
    const h0 = timeToDecimalHours(i64, f64, .{.hour = 2, .minute = 31, .second = 12});
    try expect(math. approxEqRel(f64, h0, 2.52, math.epsilon(f64)));
}

test "Test days between dates" {
    const expect = std.testing.expect;
    
    const date1:dt.AstroLocalDateTime(i64) = .{.year = 2022, .month = 4, .day = 1};
    const diff0 = daysBetweenDate(i64, f64, date1, date1);
    try expect(math.approxEqAbs(f64, diff0, 0, math.epsilon(f64)));
    
    const diff1 = daysBetweenDate(i64, f64, date1, .{.year = 2022, .month = 4, .day = 2});
    try expect(math.approxEqRel(f64, diff1, 1, math.epsilon(f64)));

    const diff2 = daysBetweenDate(i64, f64, .{.year = 2022, .month = 3, .day = 30}, date1);
    try expect(math.approxEqRel(f64, diff2, 2, math.epsilon(f64)));

    const diff3 = daysBetweenDate(i64, f64, .{.year = 1963, .month = 7, .day = 10}, date1);
    try expect(math.approxEqRel(f64, diff3, 21450, math.epsilon(f64)));
}

test "Test fix hour" {
    const expect = std.testing.expect;

    const h0 = fixHour(f64, 0);
    try expect(math.approxEqAbs(f64, h0, 0, math.epsilon(f64)));

    const h1 = fixHour(f64, 1);
    try expect(math.approxEqRel(f64, h1, 1, math.epsilon(f64)));

    const h12 = fixHour(f64, 12);
    try expect(math.approxEqRel(f64, h12, 12, math.epsilon(f64)));

    const h24 = fixHour(f64, 24);
    try expect(math.approxEqAbs(f64, h24, 0, math.epsilon(f64)));

    const h25 = fixHour(f64, 25);
    try expect(math.approxEqRel(f64, h25, 1, math.epsilon(f64)));
}
