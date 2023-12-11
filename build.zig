const std = @import("std");
const builtin = @import("builtin");
const raylib = @import("raylib/src/build.zig");

/// Add Jaylib to the exe file.
pub fn addJaylib(
    b: *std.Build,
    exe: *std.build.Step.Compile,
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
) void {
    const lib_raylib = raylib.addRaylib(b, target, optimize, .{});
    const lib = b.addStaticLibrary(.{
        .name = "jaylib",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const jaylib_flags = &[_][]const u8{
        "-std=c99",
        "-DJANET_BUILD_TYPE=release",
        "-DJANET_ENTRY_NAME=janet_module_entry_jaylib",
    };
    addCSourceFilesVersioned(lib, &.{
        srcdir ++ "/src/main.c",
    }, jaylib_flags);
    lib.addSystemIncludePath(.{ .path = srcdir ++ "/raylib/src" });
    lib.addSystemIncludePath(.{ .path = "/usr/local/include/janet" });

    exe.linkLibrary(lib_raylib);
    exe.linkLibrary(lib);
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "jaylib",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const jaylib_flags = &[_][]const u8{
        "-std=c99",
        "-DJANET_BUILD_TYPE=release",
    };
    addCSourceFilesVersioned(lib, &.{
        srcdir ++ "/src/main.c",
    }, jaylib_flags);
    lib.addSystemIncludePath(.{ .path = srcdir ++ "/raylib/src" });
    lib.addSystemIncludePath(.{ .path = "/usr/local/include/janet" });

    const lib_raylib = raylib.addRaylib(b, target, optimize, .{});
    lib.linkLibrary(lib_raylib);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);
}

const srcdir = struct {
    fn getSrcDir() []const u8 {
        return std.fs.path.dirname(@src().file).?;
    }
}.getSrcDir();

fn addCSourceFilesVersioned(exe: *std.Build.Step.Compile, files: []const []const u8, flags: []const []const u8) void {
    if (comptime builtin.zig_version.minor >= 12) {
        exe.addCSourceFiles(.{
            .files = files,
            .flags = flags,
        });
    } else {
        exe.addCSourceFiles(files, flags);
    }
}
