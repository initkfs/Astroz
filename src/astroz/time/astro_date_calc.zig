//https://ru.wikipedia.org/wiki/Дельта_T
pub fn deltaT(comptime IntType: type, comptime FloatType: type, year: IntType) FloatType {
    //2005—2050
    const delta: FloatType = 62.92 + 0.32217 * (year - 2000) + 0.005589 * ((year - 2000) ^ 2);
    return delta;
}