//! Tokenizer module for splitting expressions into tokens.

const std = @import("std");
const testing = std.testing;
const Self = @This();

/// Represents a lexical token from the input expression.
pub const Token = union(enum) {
    /// A literal string value.
    literal: []const u8,
    /// A reference to another rule.
    reference: []const u8,
    /// A special syntax symbol.
    symbol: Symbol, // '/', '~', '(', ')', etc.
};

/// Represents the supported syntax symbols.
pub const Symbol = enum {
    /// Represents the choice operator.
    choice,
    /// Represents the sequence operator.
    sequence,
    /// Represents the left parenthesis.
    left_parenthesis,
    /// Represents the right parenthesis.
    right_parenthesis,
};

/// Advances the pointer and returns the next character.
fn next(self: *Self) ?u8 {
    if (self.position >= self.input.len) return null;
    const c = self.input[self.position];
    self.position += 1;
    return c;
}

/// Returns the character at the current position without advancing.
fn peek(self: *Self) ?u8 {
    if (self.position >= self.input.len) return null;
    return self.input[self.position];
}

/// Returns the character at the current position (alias for peek without bound check).
fn now(self: Self) ?u8 {
    return self.input[self.position];
}

/// The input string to tokenize.
input: []const u8,
/// The current cursor position within the input string.
position: usize,
/// Indicates if the tokenizer is currently parsing a literal enclosed in quotes.
is_literal_mode: bool = false,

/// Parses the input string and returns an array of tokens.
// input is as:
// ```
// "True" / "False" / "Null"
// ```
pub fn tokenize(self: *Self, allocator: std.mem.Allocator) ![]const Token {
    var word: std.ArrayList(u8) = .empty;
    defer word.deinit(allocator);

    var words: std.ArrayList(Token) = .empty;
    defer words.deinit(allocator);

    while (self.peek() != null) {
        // If the word is quated
        if (self.peek().? == '"') {
            if (self.is_literal_mode) {
                const w = try word.toOwnedSlice(allocator);
                try words.append(allocator, Token{ .literal = w });
            }

            self.is_literal_mode = !self.is_literal_mode;
        }

        // Append symbols
        if (!self.is_literal_mode and self.now().? == '~') {
            try words.append(allocator, Token{ .symbol = .sequence });
            _ = self.next();

            continue;
        } else if (!self.is_literal_mode and self.now().? == '/') {
            try words.append(allocator, Token{ .symbol = .choice });
            _ = self.next();

            continue;
        } else if (!self.is_literal_mode and self.now().? == '(') {
            try words.append(allocator, Token{ .symbol = .left_parenthesis });
            _ = self.next();

            continue;
        } else if (!self.is_literal_mode and self.now().? == ')') {
            try words.append(allocator, Token{ .symbol = .right_parenthesis });
            _ = self.next();

            continue;
        }

        // Append word's character
        if (self.is_literal_mode and self.now().? != '"') {
            try word.append(allocator, self.now().?);
        }

        _ = self.next();
    }

    const result: []const Token = try words.toOwnedSlice(allocator);

    return result;
}

/// Allocates and returns a new Tokenizer instance.
pub fn new(input: []const u8, allocator: std.mem.Allocator) !*Self {
    const instance = try allocator.create(Self);

    instance.* = Self{
        .input = input,
        .position = 0,
    };

    return instance;
}

/// Frees the tokenizer instance along with the generated tokens.
pub fn free(self: *Self, allocator: std.mem.Allocator, tokens: []const Token) void {
    // Free each token's allocated memory if applicable
    for (tokens) |token| {
        switch (token) {
            .literal => |lit| allocator.free(lit),
            .reference => |ref| allocator.free(ref),
            else => {}, // Symbols don't own memory
        }
    }

    // Free the token slice itself
    allocator.free(tokens);

    // Free the tokenizer instance
    allocator.destroy(self);
}

test "Bool" {
    const expression: []const u8 =
        \\"True" / "False"
    ;

    const allocator = testing.allocator;
    const tokenizer: *Self = try Self.new(expression, allocator);
    const result: []const Token = try tokenizer.tokenize(allocator);
    defer tokenizer.free(allocator, result);

    try testing.expect(std.mem.eql(u8, result[0].literal, "True"));
    try testing.expect(std.mem.eql(u8, result[2].literal, "False"));
}

test "BoolWithNull" {
    const expression: []const u8 =
        \\"True" / "False" / "Null"
    ;

    const allocator = testing.allocator;
    const tokenizer: *Self = try Self.new(expression, allocator);
    const result: []const Token = try tokenizer.tokenize(allocator);
    defer tokenizer.free(allocator, result);

    try testing.expect(std.mem.eql(u8, result[0].literal, "True"));
    try testing.expect(result[1].symbol == .choice);
    try testing.expect(std.mem.eql(u8, result[2].literal, "False"));
    try testing.expect(result[3].symbol == .choice);
    try testing.expect(std.mem.eql(u8, result[4].literal, "Null"));
}

test "Parenthesis" {
    const expression: []const u8 =
        \\"(" ~ ")"
    ;

    const allocator = testing.allocator;
    const tokenizer: *Self = try Self.new(expression, allocator);
    const result: []const Token = try tokenizer.tokenize(allocator);
    defer tokenizer.free(allocator, result);

    try testing.expect(std.mem.eql(u8, result[0].literal, "("));
    try testing.expect(result[1].symbol == .sequence);
    try testing.expect(std.mem.eql(u8, result[2].literal, ")"));
}
