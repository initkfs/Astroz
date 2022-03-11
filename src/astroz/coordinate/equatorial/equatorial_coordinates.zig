const EquatorialRightAscension = @import("equatorial_right_ascension.zig");

pub fn EquatorialCoordinates(comptime FloatType: type) type {
    return struct {
        declination: FloatType,
        rightAscension: EquatorialRightAscension,
    };
}