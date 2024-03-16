const c = @cImport({
    @cInclude("sys/stat.h");
    @cInclude("unistd.h");
});

const std = @import("std");
const FILEPATH_MAX_LEN = 1024;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    var pathEnv = try std.process.getEnvVarOwned(allocator, "PATH");
    defer allocator.free(pathEnv);

    var it = std.mem.splitScalar(u8, @as([]const u8, pathEnv), ':');

    while (it.next()) |path| {
        var dir = std.fs.openIterableDirAbsolute(path, .{}) catch {
            continue;
        };

        defer dir.close();

        var iterator = dir.iterate();

        while (try iterator.next()) |entry| {
            if (entry.kind == std.fs.File.Kind.file) {
                var filepath = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ path, entry.name });
                defer allocator.free(filepath);

                // TODO: alloc in heap
                var filepath_with_null: [FILEPATH_MAX_LEN:0]u8 = undefined;
                @memcpy(filepath_with_null[0..filepath.len], filepath);
                filepath_with_null[filepath.len] = 0;

                var fstat: c.struct_stat = undefined;
                _ = c.stat(@as([*c]const u8, &filepath_with_null), &fstat);

                if (fstat.st_mode & c.X_OK != 0) {
                    try stdout.print("{s}\n", .{entry.name});
                }
            }
        }
    }
}
