const std = @import("std");
const math = std.math;

pub fn AngleDegCalc(comptime FloatType: type) type {
    return struct {
        const Self = @This();

        pub fn toFullCircleDeg(degs: FloatType) FloatType {
            const oneTurnDeg = 360.0;
            return degs - oneTurnDeg * math.floor(degs / oneTurnDeg);
        }

        fn toFullCircleAnyRangeDeg(valueDegs: FloatType, startDeg: FloatType, endDeg: FloatType, startDelta: FloatType, endDelta: FloatType) FloatType {
            const epsilon = math.epsilon(FloatType);

            var mustBeNormalize: FloatType = valueDegs;
            if (math.approxEqRel(FloatType, mustBeNormalize, startDeg, epsilon) or math.approxEqRel(FloatType, endDeg, epsilon)) {
                return mustBeNormalize;
            }

            //TODO there is some chance of looping and unnecessary calculations
            while (mustBeNormalize < startDeg) {
                mustBeNormalize += startDelta;
            }

            while (mustBeNormalize > endDeg) {
                mustBeNormalize -= endDelta;
            }

            return mustBeNormalize;
        }

        pub fn toFullCircleRangeDeg(valueDeg: FloatType, startDeg: FloatType, endDeg: FloatType) FloatType {
            return toFullCircleAnyRangeDeg(valueDeg, startDeg, endDeg, startDeg, endDeg);
        }

        pub fn toFullCircleNeg90To90Deg(valueDeg: FloatType) FloatType {
            return toFullCircleRangeDeg(valueDeg, -90, 90);
        }

        pub fn toFullCircleNeg180To180Deg(valueDeg: FloatType) FloatType {
            return toFullCircleRangeDeg(valueDeg, -180, 180);
        }

        pub fn toFull360CircleNeg180To180Deg(valueDeg: FloatType) FloatType {
            return toFullCircleRangeDeg(valueDeg, -180, 180, 360, 360);
        }

        pub fn hoursToDeg(hours: FloatType) FloatType {
            const secInDeg: FloatType = 360;
            const seconds: FloatType = hours * secInDeg;
            const secInHour: FloatType = 15;
            var degs = seconds * secInHour;
            degs = toFullCircleDeg(degs);
            return degs;
        }
    };
}

test "Test full circle angle" {
    const expect = std.testing.expect;
    const epsilon = math.epsilon(f64);

    try expect(math.approxEqAbs(f64, AngleDegCalc(f64).toFullCircleDeg(370), 10, epsilon));
}
