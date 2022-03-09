const std = @import("std");
const math = std.math;

pub const JulianDate = struct {
    year: i32 = -1,
    month: i32 = -1,
    day: i32 = -1,
};

pub fn gregorianToJulianJD(year: i32, month: i32, day: i32, hour: i32, min: i32, sec: i32) f64 {
    //TODO validate date
    const coeffA: i32 = @divTrunc((14 - month), 12);
    const coeffY: f64 = @intToFloat(f64, year) + 4800 - @intToFloat(f64, coeffA);
    const coeffM: f64 = @intToFloat(f64, month) + 12 * @intToFloat(f64, coeffA) - 3;

    const julianDayNumber: f64 = @intToFloat(f64, day) + @divTrunc(153 * coeffM + 2, 5) + (365 * coeffY) + @divTrunc(coeffY, 4) - @divTrunc(coeffY, 100) + @divTrunc(coeffY, 400) - 32045;

    const julianDate: f64 = julianDayNumber + ((@intToFloat(f64, hour) - 12) / 24.0) + (@intToFloat(f64, min) / 1440.0) + (@intToFloat(f64, sec) / 86400.0);
    return julianDate;
}

pub fn julianToGregorian(jdn: f64) JulianDate {
    const coeffA: f64 = jdn + 32044;
    const coeffB: i32 = @floatToInt(i32, (4 * coeffA + 3) / 146097);
    const coeffC: f64 = coeffA - @divTrunc(146097 * @intToFloat(f64, coeffB), 4);
    const coeffD: i32 = @floatToInt(i32, (4 * coeffC + 3) / 1461);
    const coeffE: f64 = coeffC - @intToFloat(f64, @divTrunc(1461 * coeffD, 4));
    const coeffM: i32 = @floatToInt(i32, (5 * coeffE + 2) / 153);

    const day: i32 = @floatToInt(i32, math.round(coeffE - @intToFloat(f64, @divTrunc(153 * coeffM + 2, 5)) + 1));
    const month: i32 = coeffM + 3 - 12 * @divTrunc(coeffM, 10);
    const year: i32 = 100 * coeffB + coeffD - 4800 + @divTrunc(coeffM, 10);

    //TODO date struct
    return .{
        .year = year,
        .month = month,
        .day = day,
    };
}

pub fn julianEphemerisDayJDE(year: i32, month: i32, day: i32, hour: i32, min: i32, sec: i32, deltaT: f64) f64 {
    const jde: f64 = gregorianToJulianJD(year, month, day, hour, min, sec) + deltaT / 86400;
    return jde;
}

pub fn julianCenturyJC(year: i32, month: i32, day: i32, hour: i32, min: i32, sec: i32) f64 {
    const jd: f64 = gregorianToJulianJD(year, month, day, hour, min, sec);
    const jc: f64 = (jd - 2451545.0) / 36525.0;
    return jc;
}

pub fn julianEphemerisCenturyJCE(year: i32, month: i32, day: i32, hour: i32, min: i32, sec: i32, deltaT: f64) f64 {
    const jde: f64 = julianEphemerisDayJDE(year, month, day, hour, min, sec, deltaT);
    const jec: f64 = (jde - 2451545) / 36525.0;
    return jec;
}

pub fn julianEphemerisMillenniumJMEfor2000(year: i32, month: i32, day: i32, hour: i32, min: i32, sec: i32, deltaT: f64) f64 {
    const jce: f64 = julianEphemerisCenturyJCE(year, month, day, hour, min, sec, deltaT);
    const jme: f64 = jce / 10;
    return jme;
}

test "Test gregorian to julian" {
    const expect = std.testing.expect;
    const epsilon = math.epsilon(f64);

    try expect(math.approxEqRel(f64, gregorianToJulianJD(2000, 1, 1, 18, 0, 0), 2451545.25, epsilon));
    try expect(math.approxEqRel(f64, gregorianToJulianJD(2022, 1, 1, 12, 20, 25), 2459581.0141782407, epsilon));
}

test "Test julian to gregorian" {
    const expect = std.testing.expect;

    const date0 = julianToGregorian(2299160.5);
    try expect(date0.year == 1582);
    try expect(date0.month == 10);
    try expect(date0.day == 15);
}
