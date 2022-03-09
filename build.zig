const std = @import("std");

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

    const mainTests = b.addTest(mainFile);
    mainTests.setBuildMode(mode);

    const testStep = b.step("test", "Run tests");
    testStep.dependOn(&mainTests.step);
}
