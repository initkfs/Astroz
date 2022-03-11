//TODO replace with any datetime package
pub fn AstroLocalDateTime(comptime IntType: type) type {
    return struct {
       year: IntType = 0,
       month: IntType = 0,
       day:IntType = 0,
       hour:IntType = 0,
       minute:IntType = 0,
       second:IntType = 0
    };
}

pub fn AstroLocalDate(comptime IntType: type) type {
    return struct {
       year: IntType = 0,
       month: IntType = 0,
       day:IntType = 0,
    };
}