const std = @import("std");

pub const clap_module = std.Build.CreateModuleOptions{
    .source_file = .{ .path = "lib/zig-clap/clap.zig" },
};

pub const csv_module = std.Build.CreateModuleOptions{
    .source_file = .{ .path = "lib/zig-csv/src/main.zig" },
};

pub fn build(b: *std.build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "csv2json",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.addAnonymousModule("clap", clap_module);
    exe.addAnonymousModule("csv", csv_module);

    b.installArtifact(exe);

    // const run_cmd = exe.run();
    // run_cmd.step.dependOn(b.getInstallStep());
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

    // var exe_tests = b.addTest("src/main.zig");
    // exe_tests.setBuildMode(mode);

    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&exe_tests.step);
}
