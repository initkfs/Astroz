const std = @import("std");
const math = std.math;

pub fn AngleDeg(comptime IntType: type, comptime FloatType: type) type {
    return struct {
        deg: IntType = 0,
        min: IntType = 0,
        sec: FloatType = 0,

        isNeg: bool = false,

        minInDeg: FloatType = 60,
        secInMin: FloatType = 60,
        secInDeg: FloatType = 3600,

        const Self = @This();

        pub fn toDecimalDeg(angle: Self) FloatType {
            const degValue: FloatType = @intToFloat(FloatType, angle.deg);
            const minValue: FloatType = @intToFloat(FloatType, angle.min);
            const result: FloatType = math.absFloat(degValue) + (math.absFloat(minValue) / angle.minInDeg) + (math.absFloat(angle.sec) / angle.secInDeg);

            if (angle.isNeg) {
                return -result;
            }

            return result;
        }

        pub fn fromDecimalDeg(value: FloatType) Self {
            var angle: Self = AngleDeg(IntType, FloatType){};

            const absValue: FloatType = math.absFloat(value);
            const deg: IntType = @floatToInt(IntType, absValue);
            const minPart: FloatType = (absValue - @intToFloat(FloatType, deg)) * angle.minInDeg;
            const min: IntType = @floatToInt(IntType, minPart);
            const sec: FloatType = ((minPart - @intToFloat(FloatType, min)) * angle.secInMin);

            const isNeg = !math.approxEqAbs(FloatType, value, 0, math.epsilon(FloatType)) and value < 0;
            angle.deg = deg;
            angle.min = min;
            angle.sec = sec;
            angle.isNeg = isNeg;
            return angle;
        }
    };
}

test "Test angle to decimal degrees" {
    const expect = std.testing.expect;
    const epsilon = math.epsilon(f64);

    try expect(math.approxEqAbs(f64, (AngleDeg(i32, f64){}).toDecimalDeg(), 0, epsilon));
    try expect(math.approxEqAbs(f64, (AngleDeg(i32, f64){ .deg = 1 }).toDecimalDeg(), 1, epsilon));
    try expect(math.approxEqAbs(f64, (AngleDeg(i32, f64){ .deg = 0, .min = 1 }).toDecimalDeg(), 0.0166666666666666, epsilon));
    try expect(math.approxEqAbs(f64, (AngleDeg(i32, f64){ .sec = 1 }).toDecimalDeg(), 0.0002777777777777778, epsilon));
    try expect(math.approxEqAbs(f64, (AngleDeg(i32, f64){ .deg = 35, .min = 3, .sec = 40.43 }).toDecimalDeg(), 35.061230555555554, epsilon));
}

test "Test decimal degrees to angle" {
    const expect = std.testing.expect;
    //35° 20' 3.26"
    const angle = AngleDeg(i32, f64).fromDecimalDeg(35.33424);
    try expect(angle.deg == 35);
    try expect(angle.min == 20);
    try expect(math.approxEqAbs(f64, angle.sec, 3.26400000000433, math.epsilon(f64)));
}
