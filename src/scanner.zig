const lox = @import("lox.zig");
const std = @import("std");

pub const Literal = union(enum) {
    string: []const u8,
    int: isize,
    float: f64,
    // TODO add IDENTIFIER?
    // maybe remove int and float in favor of number?
};

pub const TokenType = enum {
    // Single-character tokens.
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    SLASH,
    STAR,

    // One or two character tokens.
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,

    // Literals.
    IDENTIFIER,
    STRING,
    NUMBER,

    // Keywords.
    AND,
    CLASS,
    ELSE,
    FALSE,
    FUN,
    FOR,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,

    EOF,
};
pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    literal: ?Literal,
    line: usize,

    pub fn init(token_type: TokenType, lexeme: []const u8, literal: ?Literal, line: usize) Token {
        return .{
            .type = token_type,
            .lexeme = lexeme,
            .line = line,
            .literal = literal,
        };
    }

    pub fn toString(self: Token) !void {
        if (self.literal) |lit| {
            switch (lit) {
                .string => {
                    try std.io.getStdOut().writer().print("{} {s} {s}", .{
                        self.type,
                        self.lexeme,
                        lit.string,
                    });
                },
                .int => {
                    try std.io.getStdOut().writer().print("{} {s} {}", .{
                        self.type,
                        self.lexeme,
                        lit.int,
                    });
                },
                .float => {
                    try std.io.getStdOut().writer().print("{} {s} {}", .{
                        self.type,
                        self.lexeme,
                        lit.float,
                    });
                },
            }
        }
    }
};

pub const Scanner = struct {
    source: []const u8,
    tokens: std.ArrayList(Token),
    start: usize,
    current: usize,
    line: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Scanner {
        return .{
            .source = source,
            .tokens = std.ArrayList(Token).init(allocator),
            .start = 0, // "points to the first char in the lexeme being scanned"
            .current = 0, // points to the char being considered
            .line = 1, // line of current
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Scanner) void {
        self.tokens.deinit();
    }

    pub fn scanTokens(self: *Scanner) !std.ArrayList(Token) {
        while (!self.isAtEnd()) {
            self.start = self.current;
            try self.scanToken();
        }

        try self.tokens.append(Token.init(.EOF, "", null, self.line));
        return self.tokens;
    }

    fn isAtEnd(self: *Scanner) bool {
        return self.current >= self.source.len;
    }

    fn peek(self: *Scanner) u8 {
        if (self.isAtEnd()) return '\x00';
        return self.source[self.current];
    }
    fn match(self: *Scanner, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;

        self.current += 1;
        return true;
    }

    fn advance(self: *Scanner) u8 {
        const nextChar: u8 = self.source[self.current];
        self.current += 1;
        return nextChar;
    }

    fn addToken(self: *Scanner, tokenType: TokenType) !void {
        try self.addTokenWithLiteral(tokenType, null);
    }
    fn addTokenWithLiteral(self: *Scanner, tokenType: TokenType, literal: ?Literal) !void {
        const text: []const u8 = self.source[self.start..self.current];
        try self.tokens.append(Token.init(tokenType, text, literal, self.line));
    }

    fn string(self: *Scanner) !void {
        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }
        if (self.isAtEnd()) {
            try lox.print_error(self.line, "Unterminated String");
            return;
        }
        _ = self.advance();
        const value: []const u8 = self.source[self.start + 1 .. self.current - 1];
        try self.addTokenWithLiteral(.STRING, .{ .string = value });
    }

    fn scanToken(self: *Scanner) !void {
        switch (self.advance()) {
            '(' => try self.addToken(TokenType.LEFT_PAREN),
            ')' => try self.addToken(TokenType.RIGHT_PAREN),
            '{' => try self.addToken(TokenType.LEFT_BRACE),
            '}' => try self.addToken(TokenType.RIGHT_BRACE),
            ',' => try self.addToken(TokenType.COMMA),
            '.' => try self.addToken(TokenType.DOT),
            '-' => try self.addToken(TokenType.MINUS),
            '+' => try self.addToken(TokenType.PLUS),
            ';' => try self.addToken(TokenType.SEMICOLON),
            '*' => try self.addToken(TokenType.STAR),
            '!' => try self.addToken(if (self.match('='))
                TokenType.BANG_EQUAL
            else
                TokenType.BANG),
            '=' => try self.addToken(if (self.match('='))
                TokenType.EQUAL_EQUAL
            else
                TokenType.EQUAL),
            '<' => try self.addToken(if (self.match('='))
                TokenType.LESS_EQUAL
            else
                TokenType.LESS),
            '>' => try self.addToken(if (self.match('='))
                TokenType.GREATER_EQUAL
            else
                TokenType.GREATER),
            '/' => {
                if (self.match('/')) {
                    // toss tokens until end of line for comments
                    while (self.peek() != '\n' and !self.isAtEnd()) {
                        _ = self.advance();
                    }
                } else {
                    try self.addToken(.SLASH);
                }
            },
            ' ' => {},
            '\r' => {},
            '\t' => {},
            '\n' => self.line += 1,
            '"' => try self.string(),
            else => try lox.print_error(self.line, "Unexpected character."),
        }
    }
};

const tst = std.testing;

test "compile all" {
    const allocator = tst.allocator;
    var foo: Scanner = Scanner.init(allocator, "!=");
    defer foo.deinit();
    _ = try foo.scanTokens();
    try tst.expectEqual(foo.tokens.items.len, 2);
    try tst.expect(foo.tokens.items[0].type == .BANG_EQUAL);
    const token_test: Token = Token.init(.EOF, "strING", null, 0);
    try token_test.toString();
}

test "scan comment" {
    const allocator = tst.allocator;
    var foo: Scanner = Scanner.init(allocator, "// This () // is a comment ==!");
    defer foo.deinit();
    _ = try foo.scanTokens();
    try tst.expectEqual(foo.tokens.items.len, 1);
    try tst.expect(foo.tokens.items[0].type == .EOF);
}

test "string literals" {
    const allocator = tst.allocator;
    var foo: Scanner = Scanner.init(allocator,
        \\ "String literal"
    );
    defer foo.deinit();
    _ = try foo.scanTokens();

    try tst.expectEqual(foo.tokens.items.len, 2);
    try tst.expect(std.mem.eql(u8, foo.tokens.items[0].literal.?.string, "String literal"));
    try foo.tokens.items[0].toString();
}
