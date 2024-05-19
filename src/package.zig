const std = @import("std");
const data = @import("data.zig");

pub const PkgJson = struct {
    name: []const u8,
    description: []const u8,
    version: []const u8,
    author: []const u8,
    maintainer: []const u8,
    license: []const u8,
    pkg_type: []const u8,
    url: []const u8,
};

pub const PkgFrame = struct {
    data: PkgJson,
    kind: PkgTypes,
};

pub const PkgTypes = enum {
    FontZipped,
    FlatBinary,
    Unknown,
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

    const pkg_cont = std.json.parseFromSlice(PkgJson, allocator, buffer, .{ .ignore_unknown_fields = true }) catch |e| {
        std.debug.print("could not parse package.json: {s}\n", .{@errorName(e)});
        std.process.exit(0xff);
        return e; // this is here for the compiler
    };
    const pkg_json = pkg_cont.value;
    var pkg: PkgFrame = .{
        .data = pkg_json,
        .kind = PkgTypes.Unknown,
    };
    defer pkg_cont.deinit();
    try stdout.print("Download Url: {s}\n", .{pkg.data.url});
    try stdout.print("Package name: {s}\n", .{pkg.data.name});
    try stdout.print("Description: {s}\n", .{pkg.data.description});
    try stdout.print("Version: {s}\n", .{pkg.data.version});
    try stdout.print("Author: {s}\n", .{pkg.data.author});
    try stdout.print("Maintainer: {s}\n", .{pkg.data.maintainer});
    try stdout.print("License: {s}\n\n", .{pkg.data.license});
    try stdout.print("Install package? [y/n]: ", .{});
    const confirm = try std.io.getStdIn().reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 1024);
    defer allocator.free(confirm.?);

    if (!(std.mem.eql(u8, confirm.?, "y") or std.mem.eql(u8, confirm.?, "Y") or std.mem.eql(u8, confirm.?, ""))) {
        std.process.exit(0);
    }

    if (std.mem.eql(u8, pkg.data.pkg_type, "font-zipped")) {
        pkg.kind = PkgTypes.FontZipped;
    } else if (std.mem.eql(u8, pkg.data.pkg_type, "flat-binary")) {
        pkg.kind = PkgTypes.FlatBinary;
    } else {
        try stdout.print("Error: Unknown package type \"{s}\"\n", .{pkg.data.pkg_type});
        std.process.exit(0xff);
    }

    switch (pkg.kind) {
        PkgTypes.FontZipped => {
            data.zip_extract(pkg.data.url) catch |e| {
                try stdout.print("Error: Failed to extract font: \"{s}\"\n", .{@errorName(e)});
                std.process.exit(0xff);
            };
        },
        PkgTypes.FlatBinary => {
            try stdout.print("Error: Flat binaries are not supported yet.\n", .{});
            std.process.exit(0xff);
        },
        else => {
            try stdout.print("Error: Invalid package kind: \"{s}\"\n", .{@tagName(pkg.kind)});
            std.process.exit(0xff);
        },
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

    const body = try request.reader().readAllAlloc(allocator, std.math.maxInt(usize));

    return body;
}
