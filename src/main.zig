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

    if (std.mem.eql(u8, "help", args.next().?)) {
        try comms.help();
        std.process.exit(0);
    }

    const config = try conf.getConf();
    const repos = try conf.getRepos(config);

    if (std.mem.eql(u8, "install", args.next().?)) {
        try comms.install(repos, args.next().?);
        std.process.exit(0);
    }

    const command = args.next().?;

    try stdout.print("Unknown command: {s}\n", .{command});
}