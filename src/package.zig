const std = @import("std");

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

pub fn install(url: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
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
        std.process.exit(0xff);
    }

    try stdout.print("Installing package...\n", .{});



    try stdout.print("Done!\n", .{});

}

pub fn getBuffFromUrl(allocator: std.mem.Allocator, url: []const u8) ![]u8 {
    const uri = std.Uri.parse(url) catch unreachable;

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var request = try client.open(.GET, uri, .{ .server_header_buffer = try allocator.alloc(u8, 1024) });
    defer request.deinit();

    try request.send();
    try request.wait();

    const body = try request.reader().readAllAlloc(allocator, 8192);

    return body;
}
