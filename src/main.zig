const std = @import("std");
const r = @import("repo.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const repo = try r.init("testrepo.json");
    try stdout.print("name: {s}\n", .{repo.name});
    try stdout.print("description: {s}\n", .{repo.description});
    for (repo.urls) |url| {
        try stdout.print("url: {s}\n", .{url});
    }
}