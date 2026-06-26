//! Build script for the zigpeg library.

const std = @import("std");
const l = @import("lightmix");

/// Standard build function.
pub fn build(b: *std.Build) anyerror!void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Modules
    const mod = b.createModule(.{
        .root_source_file = b.path("src/zigpeg.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{},
    });

    // Static Library Install
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "zigpeg",
        .root_module = mod,
    });
    b.installArtifact(lib);

    // Unit tests
    const unit_tests = b.addTest(.{ .root_module = mod });
    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Test step
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
