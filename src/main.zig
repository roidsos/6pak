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
        if (args.next()) |arg| {
            try comms.install(repos, arg);
            std.process.exit(0);
        } else {
            try stdout.print("Error: Install expects a sub command. Example: spak install <package>\n", .{});
            std.process.exit(1);
        }
    }

    try stdout.print("Error: Unknown command: {s}\n", .{command});
}
