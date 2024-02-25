const scanner = @import("./scanner.zig");
const lox = @import("./lox.zig");

const std = @import("std");
const fs = std.fs;

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    switch (args.len) {
        1 => try lox.runPrompt(allocator),
        2 => try lox.runFile(allocator, args[1]),
        else => {
            std.debug.print("Usage zig-lox [script]", .{});
            return 64;
        },
    }
    const foo = scanner.Scanner.init(allocator, ""); // for zig to check my code
    _ = foo;
    return 0;
}
