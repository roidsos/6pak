const std = @import("std");
const r = @import("repo.zig");
const pkg = @import("package.zig");

pub fn help() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("help.\n", .{});
}

pub fn install(repos: []const r.Repo, name: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    for (repos) |repo| {
        for (repo.packages) |pak| {
            if (std.mem.eql(u8, name, pak.name)) {
                try stdout.print("Installing \"{s}\"\n", .{pak.name});
                pkg.install(pak.url) catch |err| {
                    std.debug.print("Failed to install {s} ERROR: \"{s}\"\n", .{ pak.name, @errorName(err) });
                    std.process.exit(0xff);
                };
                return;
            }
        }
    }
    try stdout.print("Could not find package \"{s}\"\n", .{name});
}
