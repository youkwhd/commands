const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    var pathEnv = try std.process.getEnvVarOwned(allocator, "PATH");
    defer allocator.free(pathEnv);

    var it = std.mem.splitScalar(u8, @as([]const u8, pathEnv), ':');

    while (it.next()) |path| {
        try stdout.print("{s}\n", .{path});

        var dir = std.fs.openIterableDirAbsolute(path, .{}) catch {
            continue;
        };

        defer dir.close();

        var iterator = dir.iterate();

        while (try iterator.next()) |entry| {
            if (entry.kind == std.fs.File.Kind.file) {
                var filepath = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ path, entry.name });
                defer allocator.free(filepath);

                // bruh ain't no way i MUST open
                // only for File.stat()
                var file = try std.fs.openFileAbsolute(filepath, .{});
                defer file.close();

                var filestat = try file.stat();
                _ = filestat;
            }
        }
    }
}
