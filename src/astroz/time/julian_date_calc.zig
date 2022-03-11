const std = @import("std");
const math = std.math;
const dt = @import("astro_local_datetime.zig");

pub fn gregorianToJulianJD(comptime IntType: type, comptime FloatType: type, dateTime: dt.AstroLocalDateTime(IntType)) FloatType {
    //TODO validate date
    const coeffA: IntType = @divTrunc((14 - dateTime.month), 12);
    const coeffY: FloatType = @intToFloat(FloatType, dateTime.year) + 4800 - @intToFloat(FloatType, coeffA);
    const coeffM: FloatType = @intToFloat(FloatType, dateTime.month) + 12 * @intToFloat(FloatType, coeffA) - 3;

    const julianDayNumber: FloatType = @intToFloat(FloatType, dateTime.day) + @divTrunc(153 * coeffM + 2, 5) + (365 * coeffY) + @divTrunc(coeffY, 4) - @divTrunc(coeffY, 100) + @divTrunc(coeffY, 400) - 32045;

    const julianDate: FloatType = julianDayNumber + ((@intToFloat(FloatType, dateTime.hour) - 12) / 24.0) + (@intToFloat(FloatType, dateTime.minute) / 1440.0) + (@intToFloat(FloatType, dateTime.second) / 86400.0);
    return julianDate;
}

pub fn julianToGregorian(comptime IntType: type, comptime FloatType: type, jdn: FloatType) dt.AstroLocalDate(IntType) {
    const coeffA: FloatType = jdn + 32044;
    const coeffB: IntType = @floatToInt(IntType, (4 * coeffA + 3) / 146097);
    const coeffC: FloatType = coeffA - @divTrunc(146097 * @intToFloat(FloatType, coeffB), 4);
    const coeffD: IntType = @floatToInt(IntType, (4 * coeffC + 3) / 1461);
    const coeffE: FloatType = coeffC - @intToFloat(FloatType, @divTrunc(1461 * coeffD, 4));
    const coeffM: IntType = @floatToInt(IntType, (5 * coeffE + 2) / 153);

    const day: IntType = @floatToInt(IntType, math.round(coeffE - @intToFloat(FloatType, @divTrunc(153 * coeffM + 2, 5)) + 1));
    const month: IntType = coeffM + 3 - 12 * @divTrunc(coeffM, 10);
    const year: IntType = 100 * coeffB + coeffD - 4800 + @divTrunc(coeffM, 10);

    //TODO date struct
    return .{
        .year = year,
        .month = month,
        .day = day,
    };
}

pub fn julianEphemerisDayJDE(comptime IntType: type, comptime FloatType: type, dateTime: dt.AstroLocalDateTime, deltaT: FloatType) FloatType {
    const jde: FloatType = gregorianToJulianJD(IntType, FloatType, dateTime) + deltaT / 86400;
    return jde;
}

pub fn julianCenturyJC(comptime IntType: type, comptime FloatType: type, dateTime: dt.AstroLocalDateTime) FloatType {
    const jd: FloatType = gregorianToJulianJD(IntType, FloatType, dateTime);
    const jc: FloatType = (jd - 2451545.0) / 36525.0;
    return jc;
}

pub fn julianEphemerisCenturyJCE(comptime IntType: type, comptime FloatType: type, dateTime: dt.AstroLocalDateTime, deltaT: FloatType) FloatType {
    const jde: FloatType = julianEphemerisDayJDE(IntType, FloatType, dateTime, deltaT);
    const jec: FloatType = (jde - 2451545) / 36525.0;
    return jec;
}

pub fn julianEphemerisMillenniumJMEfor2000(comptime IntType: type, comptime FloatType: type, dateTime: dt.AstroLocalDateTime(IntType), deltaT: FloatType) FloatType {
    const jce: FloatType = julianEphemerisCenturyJCE(IntType, FloatType, dateTime, deltaT);
    const jme: FloatType = jce / 10;
    return jme;
}

test "Test gregorian to julian" {
    const expect = std.testing.expect;
    const epsilon = math.epsilon(f64);

    try expect(math.approxEqRel(f64, gregorianToJulianJD(i64, f64, .{ .year = 2000, .month = 1, .day = 1, .hour = 18 }), 2451545.25, epsilon));
    try expect(math.approxEqRel(f64, gregorianToJulianJD(i64, f64, .{ .year = 2022, .month = 1, .day = 1, .hour = 12, .minute = 20, .second = 25 }), 2459581.0141782407, epsilon));
}

test "Test julian to gregorian" {
    const expect = std.testing.expect;

    const date0 = julianToGregorian(i64, f64, 2299160.5);
    try expect(date0.year == 1582);
    try expect(date0.month == 10);
    try expect(date0.day == 15);
}
