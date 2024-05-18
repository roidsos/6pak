const std = @import("std");

// becuz im lazy
const http = std.http;

pub fn install(url: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(" - Downloading \"{s}\"\n", .{url});

    const allocator = std.heap.page_allocator;
    const buffer = try getBuffFromUrl(allocator, url);
    defer allocator.free(buffer);
    std.debug.print("{any}\n", .{buffer});
}

pub fn getBuffFromUrl(allocator: std.mem.Allocator, url: []const u8) ![]u8 {
    _ = allocator;
    _ = url;

    const buffer: []u8 = undefined;
    return buffer;
}
