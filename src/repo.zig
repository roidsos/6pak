const std = @import("std");

pub const Repo = struct {
    name: []const u8,
    description: []const u8,
    version: []const u8,
    packages: []const struct {
        name: []const u8,
        url: []const u8,
    },
};

pub fn init(path: []const u8) !Repo {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const file_buf: []u8 = try file.readToEndAlloc(std.heap.page_allocator, 1024 * 1024);
    return (std.json.parseFromSlice(Repo, std.heap.page_allocator, file_buf, .{}) catch |err| {
        std.debug.print("Error parsing JSON: {s}\n", .{@errorName(err)});
        std.process.exit(0xff);
        return err; // wont get here anyways lul
    }).value;
}
