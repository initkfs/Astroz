pub fn HeliocentricEclipticCoordinates(comptime FloatType: type) type {
    return struct {
        longitudeDeg: FloatType = 0,
        latitudeDeg: FloatType = 0,
        distanceAstroUnits: FloatType = 0,
    };
}