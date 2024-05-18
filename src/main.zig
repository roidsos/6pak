const std = @import("std");

//loaders
const repo = @import("repo.zig");
const conf = @import("conf.zig");

//commands
const comms = @import("commands.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var args = std.process.args();

    if (args.inner.count < 2) {
        try comms.help();
        std.process.exit(0);
    }

    _ = args.next();
    const command = args.next().?;

    if (std.mem.eql(u8, "help", command)) {
        try comms.help();
        std.process.exit(0);
    }

    const config = try conf.getConf();
    const repos = try conf.getRepos(config);

    if (std.mem.eql(u8, "install", command)) {
        try comms.install(repos, args.next().?);
        std.process.exit(0);
    }

    try stdout.print("Unknown command: {s}\n", .{command});
}
