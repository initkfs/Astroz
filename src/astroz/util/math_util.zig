const std = @import("std");
const math = std.math;

//TODO division with integer and fractional types
pub fn linearInterp(comptime T: type, x1: T, x2: T, y1: T, y2: T, x: T) T {
    return y1 + (x - x1) * ((y2 - y1) / (x2 - x1));
}

pub fn lagrangeInterp(comptime T: type, arrX: []const T, arrY: []const T, x: T) T {
    //TODO validate input arrays arrX.len == arrY.len
    const numberOfPoints: usize = arrX.len;
    var sum: T = 0;
    var i: usize = 0;
    while (i < numberOfPoints) : (i += 1) {
        var lg: T = 1;
        var j: usize = 0;
        while (j < numberOfPoints) : (j += 1) {
            if (i != j) {
                lg = lg * (x - arrX[j]) / (arrX[i] - arrX[j]);
            }
        }
        sum = sum + lg * arrY[i];
    }
    return sum;
}

test "Test linear interpolation" {
    const fType = f64;
    try std.testing.expect(math.approxEqRel(fType, linearInterp(fType, 10, 12, 13, 14, 5), 10.5, math.epsilon(fType)));
    try std.testing.expect(math.approxEqRel(fType, linearInterp(fType, 0.1, 0.5, 0.22, 0.44, 0.15), 0.2475, math.epsilon(fType)));
}

test "Test Lagrange interpolation" {
    try std.testing.expect(math.approxEqRel(f64, lagrangeInterp(f64, &[_]f64{ 100, 102, 105, 108 }, &[_]f64{ 1.4371, 1.4629, 1.5343, 1.6571 }, 103), 1.48183333, math.epsilon(f32)));
}
