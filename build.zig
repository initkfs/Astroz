const std = @import("std");
const mem = std.mem;
const panic = std.debug.panic;

pub fn build(b: *std.build.Builder) void {
    var features = std.Target.Cpu.Feature.Set.empty;
    features.addFeatureSet(std.Target.x86.cpu.x86_64.features);

    const target: std.zig.CrossTarget = .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
        .cpu_model = .{ .explicit = &std.Target.x86.cpu.x86_64 },
        .cpu_features_add = features,
    };

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const appName = "astroz";
    const mainFile = "src/main.zig";

    const exe = b.addExecutable(appName, mainFile);
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const runAppStep = exe.run();
    //in the cli: -- -h
    if (b.args) |args| {
        runAppStep.addArgs(args);
    }

    const step = b.step("run", "Run executable");
    step.dependOn(&runAppStep.step);

    const allocator = std.heap.page_allocator;
    
    //TODO ./src path?
    var sourceDir = std.fs.cwd().openIterableDir("..", .{}) catch |err| panic("Error opening source directory: {}", .{err});
    defer sourceDir.close();

    var walker = sourceDir.walk(allocator) catch |err| panic("Source directory walk error: {}", .{err});
    defer walker.deinit();

    const testStep = b.step("test", "Run tests");

    while (walker.next()) |mustBeEntry| {
        if (mustBeEntry) |entry| {
            const path = entry.path;
            if (entry.kind != .File or !mem.endsWith(u8, path, ".zig") or std.mem.indexOf(u8, path, "zig-cache") != null) {
                continue;
            }

            const fullPath = mem.concat(allocator, u8, &[_][]const u8{ "./src/", path }) catch |err| panic("Full test file path concatenation error: {}", .{err});
            std.debug.print("Found test file: {s}\n", .{fullPath});
            defer allocator.free(fullPath);
            
            const testFile = b.addTest(fullPath);
            testFile.setBuildMode(mode);
            testStep.dependOn(&testFile.step);
        } else {
            break;
        }
    } else |_| {
        unreachable;
    }
}
