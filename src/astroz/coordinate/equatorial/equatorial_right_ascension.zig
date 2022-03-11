pub fn EquatorialRightAscension(comptime FloatType: type) type {
    return struct {
        deg: FloatType,
        hours: FloatType,
    };
}
