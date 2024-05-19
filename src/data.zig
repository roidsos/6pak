const std = @import("std");
const zip_dot_zig = @import("vendor/zip.zig");
const pkg = @import("package.zig");

pub fn zip_extract(url: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;

    try stdout.print("Installing zipped font...\n", .{});

    const zip = pkg.getBuffFromUrl(allocator, url) catch |e| {
        return e;
    };
    defer allocator.free(zip);
    const tmpdir = try std.fs.openDirAbsolute("/tmp", .{});
    const fontsdir = try std.fs.cwd().makeOpenPath("fonts", .{});
    try tmpdir.deleteFile("font.zip");
    try tmpdir.writeFile("font.zip", zip);
    const zipfile = try tmpdir.openFile("font.zip", .{});

    try zip_dot_zig.extract(fontsdir, zipfile.seekableStream(), .{});
}
