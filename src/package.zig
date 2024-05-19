const std = @import("std");

pub fn install(url: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Downloading the package...\n", .{});

    const allocator = std.heap.page_allocator;
    const buffer = getBuffFromUrl(allocator, url) catch |e| {
        std.debug.print("could not download package.json: {s}\n", .{@errorName(e)});
        std.process.exit(0xff);
        return e; // this is here for the compiler
    };
    defer allocator.free(buffer);
    std.debug.print("{s}\n", .{buffer});
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
