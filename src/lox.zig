const std = @import("std");
const fs = std.fs;

pub fn dbg(comptime x: []const u8) void {
    std.debug.print(x, .{});
    std.debug.print("\n", .{});
}

var hadError = false;

pub fn run(source: []const u8) void {
    std.debug.print("{s}", .{source});
}

pub fn runPrompt(allocator: std.mem.Allocator) !void {
    const stdin_file = std.io.getStdIn();
    var buffered_reader = std.io.bufferedReader(stdin_file.reader());
    const stdin = buffered_reader.reader();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    const writer = line.writer();

    while (stdin.streamUntilDelimiter(writer, '\n', null)) {
        defer line.clearRetainingCapacity();
        run(line.items);
        hadError = false;
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }
}

pub fn runFile(allocator: std.mem.Allocator, file: [:0]u8) !void {
    var open_file = try fs.cwd().openFile(file, .{});
    defer open_file.close();
    const file_len = try open_file.getEndPos();

    const buf = try allocator.alloc(u8, file_len);
    defer allocator.free(buf);

    _ = try open_file.readAll(buf);

    run(buf);
    if (hadError) std.os.exit(65);
}

pub fn report(line: usize, where: []const u8, message: []const u8) !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("[line {d}] Error {s}: {s}\n", .{ line, where, message });
    hadError = true;
}
pub fn print_error(line: usize, message: []const u8) !void {
    try report(line, "", message);
}
