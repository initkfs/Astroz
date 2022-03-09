const std = @import("std");
const stdout = std.io.getStdOut().writer();

const angle_deg = @import("astroz/angle/angle_deg.zig");

pub fn main() !void {
    try stdout.print("Angle: {d}.\n", .{@as(angle_deg.AngleDeg, .{ .deg = 30 }).deg});
}
