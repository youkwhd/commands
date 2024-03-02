const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    var pathEnv = try std.process.getEnvVarOwned(allocator, "PATH");
    defer allocator.free(pathEnv);

    try stdout.print("{s}\n", .{pathEnv});
}
