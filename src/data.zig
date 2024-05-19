const std = @import("std");
const zip_dot_zig = @import("vendor/zip.zig");
const pkg = @import("package.zig");

pub fn font_zip_extract(p: pkg.PkgFrame) !void {
    const stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;

    try stdout.print("==> Installing zipped font...\n", .{});

    const zip = pkg.getBuffFromUrl(allocator, p.data.url) catch |e| {
        return e;
    };

    defer allocator.free(zip);
    var tmp: std.testing.TmpDir = std.testing.tmpDir(.{ .access_sub_paths = true, .iterate = false, .no_follow = false });
    const tmpdir = tmp.dir;
    const fontsdir = try std.fs.cwd().makeOpenPath("fonts", .{});
    fontsdir.deleteTree(p.data.name) catch |e| {
        if (std.mem.eql(u8, @errorName(e), "FileNotFound")) {
            try stdout.print("==> Warning: Font already exists. Reinstalling.\n", .{});
        } else {
            return e;
        }
    };

    try fontsdir.makeDir(p.data.name);
    const fontdir = try fontsdir.openDir(p.data.name, .{});

    try tmpdir.writeFile("font.zip", zip);
    const zipfile = try tmpdir.openFile("font.zip", .{});

    try zip_dot_zig.extract(fontdir, zipfile.seekableStream(), .{});
    tmp.cleanup();
    try stdout.print("==> Installed font \"{s}\".\n", .{p.data.name});
}
