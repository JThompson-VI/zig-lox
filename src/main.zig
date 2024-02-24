const std = @import("std");
const fs = std.fs;

fn dbg(comptime x: []const u8) void {
    std.debug.print(x, .{});
    std.debug.print("\n", .{});
}

fn run(source: []const u8) void {
    std.debug.print("{s}", .{source});
}

fn runPrompt(allocator: std.mem.Allocator) !void {
    const stdin_file = std.io.getStdIn();
    var buffered_reader = std.io.bufferedReader(stdin_file.reader());
    const stdin = buffered_reader.reader();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    const writer = line.writer();

    while (stdin.streamUntilDelimiter(writer, '\n', null)) {
        defer line.clearRetainingCapacity();
        run(line.items);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }
}

fn runFile(allocator: std.mem.Allocator, file: [:0]u8) !void {
    var open_file = try fs.cwd().openFile(file, .{});
    defer open_file.close();
    const file_len = try open_file.getEndPos();

    const buf = try allocator.alloc(u8, file_len);
    defer allocator.free(buf);

    _ = try open_file.readAll(buf);

    run(buf);
}

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    switch (args.len) {
        1 => try runPrompt(allocator),
        2 => try runFile(allocator, args[1]),
        else => {
            std.debug.print("Usage zig-lox [script]", .{});
            return 64;
        },
    }
    return 0;
}
