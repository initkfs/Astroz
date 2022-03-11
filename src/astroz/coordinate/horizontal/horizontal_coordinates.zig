pub fn HorizontalCoordinates(comptime FloatType: type) type {
    return struct {
        altitudeDeg: FloatType,
        azimuthDeg: FloatType,
    };
}
