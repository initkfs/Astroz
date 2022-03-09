const std = @import("std");
const math = std.math;

pub fn toFullCircleDeg(degs: f64) f64 {
    const oneTurnDeg = 360.0;
    return degs - oneTurnDeg * math.floor(degs / oneTurnDeg);
}

fn toFullCircleAnyRangeDeg(valueDegs: f64, startDeg: f64, endDeg: f64, startDelta: f64, endDelta: f64) f64 {
    const epsilon = math.epsilon(f64);

    var mustBeNormalize: f64 = valueDegs;
    if (math.approxEqRel(f64, mustBeNormalize, startDeg, epsilon) or math.approxEqRel(f64, endDeg, epsilon)) {
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

pub fn toFullCircleRangeDeg(valueDeg: f64, startDeg: f64, endDeg: f64) f64 {
    return toFullCircleAnyRangeDeg(valueDeg, startDeg, endDeg, startDeg, endDeg);
}

pub fn toFullCircleNeg90To90Deg(valueDeg: f64) f64 {
    return toFullCircleRangeDeg(valueDeg, -90, 90);
}

pub fn toFullCircleNeg180To180Deg(valueDeg: f64) f64 {
    return toFullCircleRangeDeg(valueDeg, -180, 180);
}

pub fn toFull360CircleNeg180To180Deg(valueDeg: f64) f64 {
    return toFullCircleRangeDeg(valueDeg, -180, 180, 360, 360);
}

pub fn hoursToDeg(hours: f64) f64 {
    const secInDeg: f64 = 360;
    const seconds: f64 = hours * secInDeg;
    const secInHour: f64 = 15;
    var degs = seconds * secInHour;
    degs = toFullCircleDeg(degs);
    return degs;
}

test "Test full circle angle" {
    const expect = std.testing.expect;
    const epsilon = math.epsilon(f64);

    try expect(math.approxEqAbs(f64, toFullCircleDeg(370), 10, epsilon));
}
