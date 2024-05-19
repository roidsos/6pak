const std = @import("std");
const zip_dot_zig = @import("vendor/zip.zig");

pub const PkgJson = struct {
    name: []const u8,
    description: []const u8,
    version: []const u8,
    author: []const u8,
    maintainer: []const u8,
    license: []const u8,
    pkg_type: []const u8,
    url: []const u8
};
const stdout = std.io.getStdOut().writer();

pub fn install(url: []const u8) !void {
    try stdout.print("Downloading the package...\n\n", .{});

    const allocator = std.heap.page_allocator;
    const buffer = getBuffFromUrl(allocator, url) catch |e| {
        std.debug.print("could not download package.json: {s}\n", .{@errorName(e)});
        std.process.exit(0xff);
        return e; // this is here for the compiler
    };
    defer allocator.free(buffer);

    const pkg_cont = std.json.parseFromSlice(PkgJson, allocator, buffer, .{.ignore_unknown_fields = true}) catch |e| {
        std.debug.print("could not parse package.json: {s}\n", .{@errorName(e)});
        std.process.exit(0xff);
        return e; // this is here for the compiler
    };
    const pkg = pkg_cont.value;
    defer pkg_cont.deinit();

    try stdout.print("Package name: {s}\n", .{pkg.name});
    try stdout.print("Description: {s}\n", .{pkg.description});
    try stdout.print("Version: {s}\n", .{pkg.version});
    try stdout.print("Author: {s}\n", .{pkg.author});
    try stdout.print("Maintainer: {s}\n", .{pkg.maintainer});
    try stdout.print("License: {s}\n\n", .{pkg.license});
    try stdout.print("Install package? [y/n]: ", .{});
    const confirm = try std.io.getStdIn().reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 1024);
    defer allocator.free(confirm.?);

    if (!(std.mem.eql(u8, confirm.?, "y") or std.mem.eql(u8, confirm.?, "Y"))) {
        std.process.exit(0);
    }


    if (std.mem.eql(u8, pkg.pkg_type, "font-zipped")) {
        try stdout.print("Installing zipped font...\n", .{});

        const zip = getBuffFromUrl(allocator, pkg.url) catch |e| {
            std.debug.print("could not download font: {s}\n", .{@errorName(e)});
            std.process.exit(0xff);
            return e; // this is here for the compiler
        };
        defer allocator.free(zip);

        const tmpdir = try std.fs.openDirAbsolute("/tmp", .{});
        const fontsdir = try std.fs.cwd().makeOpenPath("fonts", .{});

        try tmpdir.deleteFile("font.zip"); // make sure font.zip isnt already there
        try tmpdir.writeFile("font.zip", zip);
        const zipfile = try tmpdir.openFile("font.zip", .{});
        
        try zip_dot_zig.extract(fontsdir,zipfile.seekableStream(), .{});

    } else {
        try stdout.print("Error: Unknown package type\n", .{});
        std.process.exit(0xff);
    }
    try stdout.print("Done!\n", .{});

}

pub fn getBuffFromUrl(allocator: std.mem.Allocator, url: []const u8) ![]u8 {
    const uri = std.Uri.parse(url) catch unreachable;

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var request = try client.open(.GET, uri, .{ .server_header_buffer = try allocator.alloc(u8, 4096) });
    defer request.deinit();

    try request.send();
    try request.wait();

    if (request.response.content_length.? > 1024 * 1024 * 1024 * 4) { // file over 4Gib
        // something fishy is going on, prompt the user to confirm that the file is correct
        try stdout.print("Fie at \"{s}\" is over 4Gib, are you sure your repos are updated?? [y/n]: ", .{url});
        const confirm = try std.io.getStdIn().reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 1024);
        defer allocator.free(confirm.?);

        if (!(std.mem.eql(u8, confirm.?, "y") or std.mem.eql(u8, confirm.?, "Y"))) {
            std.process.exit(0);
        }
    }
    //std.debug.print("Downloaded {d} bytes from \"{s}\"\n", .{request.response.content_length.?, url});
    // TODO: why is content_length bad?
    const body = try request.reader().readAllAlloc(allocator, request.response.content_length.? * 2);

    return body;
}
