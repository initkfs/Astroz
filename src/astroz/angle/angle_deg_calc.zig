const std = @import("std");
const math = std.math;

pub fn toFullCircleDeg(comptime FloatType: type, degs: FloatType) FloatType {
    const oneTurnDeg = 360.0;
    return degs - oneTurnDeg * math.floor(degs / oneTurnDeg);
}

fn toFullCircleAnyRangeDeg(comptime FloatType: type, valueDegs: FloatType, startDeg: FloatType, endDeg: FloatType, startDelta: FloatType, endDelta: FloatType) FloatType {
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

pub fn toFullCircleRangeDeg(comptime FloatType: type, valueDeg: FloatType, startDeg: FloatType, endDeg: FloatType) FloatType {
    return toFullCircleAnyRangeDeg(FloatType, valueDeg, startDeg, endDeg, startDeg, endDeg);
}

pub fn toFullCircleNeg90To90Deg(comptime FloatType: type, valueDeg: FloatType) FloatType {
    return toFullCircleRangeDeg(FloatType, valueDeg, -90, 90);
}

pub fn toFullCircleNeg180To180Deg(comptime FloatType: type, valueDeg: FloatType) FloatType {
    return toFullCircleRangeDeg(FloatType, valueDeg, -180, 180);
}

pub fn toFull360CircleNeg180To180Deg(comptime FloatType: type, valueDeg: FloatType) FloatType {
    return toFullCircleRangeDeg(FloatType, valueDeg, -180, 180, 360, 360);
}

pub fn hoursToDeg(comptime FloatType: type, hours: FloatType) FloatType {
    const secInDeg: FloatType = 360;
    const seconds: FloatType = hours * secInDeg;
    const secInHour: FloatType = 15;
    var degs = seconds * secInHour;
    degs = toFullCircleDeg(degs);
    return degs;
}

test "Test full circle angle" {
    const expect = std.testing.expect;
    const epsilon = math.epsilon(f64);

    try expect(math.approxEqAbs(f64, toFullCircleDeg(f64, 370), 10, epsilon));
}
