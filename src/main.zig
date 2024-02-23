const std = @import("std");

fn dbg(comptime x: []const u8) void {
    std.debug.print(x, .{});
    std.debug.print("\n", .{});
}

pub fn main() !void {
    const std_out_file = std.io.getStdOut();
    var bw = std.io.bufferedWriter(std_out_file.writer());
    const std_out = bw.writer();

    dbg("dbg is working");
    try std_out.print("Hello World\n", .{});

    try bw.flush();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
