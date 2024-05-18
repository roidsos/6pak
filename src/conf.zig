const std = @import("std");
const r = @import("repo.zig");
pub const Conf = struct{
    repos: []const []const u8,
};

pub fn getConf() !Conf {
    var file = try std.fs.cwd().openFile("conf.json", .{});
    defer file.close();
    const file_buf: []u8 = try file.readToEndAlloc(std.heap.page_allocator, 1024 * 1024); 
    return (std.json.parseFromSlice( Conf,std.heap.page_allocator,file_buf,.{}) catch |err| {
        std.debug.print("Error parsing JSON: {s}\n", .{@errorName(err)});
        std.process.exit(0xff);
        return err; // wont get here anyways lul
    }).value;
}
pub fn getRepos(conf: Conf) ![]const r.Repo  {
    var repos = std.ArrayList(r.Repo).init(std.heap.page_allocator);
    for(conf.repos) |repo| {
        try repos.append(try r.init(repo));
    }
    return repos.toOwnedSlice();
}