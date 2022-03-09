const std = @import("std");
const math = std.math;

pub const AngleDeg = struct {
    deg: i32 = 0,
    min: i32 = 0,
    sec: f64 = 0,

    isNeg: bool = false,

    minInDeg: f64 = 60,
    secInMin: f64 = 60,
    secInDeg: f64 = 3600,

    pub fn toDecimalDeg(self: AngleDeg) f64 {
        return toDecimalDegFloat(f64, self);
    }

    pub fn toDecimalDegFloat(comptime T: type, angle: AngleDeg) T {
        const degValue: T = @intToFloat(T, angle.deg);
        const minValue: T = @intToFloat(T, angle.min);
        const result: T = math.absFloat(degValue) + (math.absFloat(minValue) / angle.minInDeg) + (math.absFloat(angle.sec) / angle.secInDeg);

        if (angle.isNeg) {
            return -result;
        }

        return result;
    }

    pub fn fromDecimalDeg(value: f64) AngleDeg {
        var angle: AngleDeg = .{};

        const absValue: f64 = math.absFloat(value);
        const deg: i32 = @floatToInt(i32, absValue);
        const minPart: f64 = (absValue - @intToFloat(f64, deg)) * angle.minInDeg;
        const min: i32 = @floatToInt(i32, minPart);
        const sec: f64 = ((minPart - @intToFloat(f64, min)) * angle.secInMin);

        const isNeg = !math.approxEqAbs(f64, value, 0, math.epsilon(f64)) and value < 0;
        angle.deg = deg;
        angle.min = min;
        angle.sec = sec;
        angle.isNeg = isNeg;
        return angle;
    }
};

test "Test angle to decimal degrees" {
    const expect = std.testing.expect;
    const epsilon = math.epsilon(f64);

    try expect(math.approxEqAbs(f64, (@as(AngleDeg, .{})).toDecimalDeg(), 0, epsilon));
    try expect(math.approxEqAbs(f64, (@as(AngleDeg, .{ .deg = 1 })).toDecimalDeg(), 1, epsilon));
    try expect(math.approxEqAbs(f64, (@as(AngleDeg, .{ .deg = 0, .min = 1 })).toDecimalDeg(), 0.0166666666666666, epsilon));
    try expect(math.approxEqAbs(f64, (@as(AngleDeg, .{ .sec = 1 })).toDecimalDeg(), 0.0002777777777777778, epsilon));
    try expect(math.approxEqAbs(f64, (@as(AngleDeg, .{ .deg = 35, .min = 3, .sec = 40.43 })).toDecimalDeg(), 35.061230555555554, epsilon));
}

test "Test decimal degrees to angle" {
    const expect = std.testing.expect;
    //35° 20' 3.26"
    const angle = AngleDeg.fromDecimalDeg(35.33424);
    try expect(angle.deg == 35);
    try expect(angle.min == 20);
    try expect(math.approxEqAbs(f64, angle.sec, 3.26400000000433, math.epsilon(f64)));
}
