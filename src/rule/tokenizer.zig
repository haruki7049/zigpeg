const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const Self = @This();

pub const Token = union(enum) {
    literal: []const u8,
    reference: []const u8,
    symbol: u8, // '/', '~', '(', ')', etc.
};

fn next(self: *Self) ?u8 {
    if (self.position >= self.input.len) return null;
    const c = self.input[self.position];
    self.position += 1;
    return c;
}

fn peek(self: *Self) ?u8 {
    if (self.position >= self.input.len) return null;
    return self.input[self.position];
}

fn now(self: Self) ?u8 {
    return self.input[self.position];
}

input: []const u8,
position: usize,
is_literal_mode: bool = false,

// input is as:
// ```
// "True" / "False" / "Null"
// ```
pub fn tokenize(self: *Self, allocator: std.mem.Allocator) ![]const Token {
    var word = ArrayList(u8).init(allocator);
    defer word.deinit();

    var words = ArrayList(Token).init(allocator);
    defer words.deinit();

    while (self.peek() != null) {
        // If the word is quated
        if (self.peek().? == '"') {
            self.is_literal_mode = !self.is_literal_mode;

            if (self.is_literal_mode == false) {
                const w = try word.toOwnedSlice();
                try words.append(Token{ .literal = w });
            }
        }

        // Append word's character
        if (self.is_literal_mode and self.now().? != '"') {
            try word.append(self.now().?);
        }

        // Append symbols
        if (self.now().? == '/' or self.now().? == '~' or self.now().? == '(' or self.now().? == ')') {
            try words.append(Token{ .symbol = self.now().? });
        }

        _ = self.next();
    }

    const result: []const Token = try words.toOwnedSlice();

    return result;
}

pub fn new(input: []const u8, allocator: std.mem.Allocator) !*Self {
    const instance = try allocator.create(Self);
    instance.* = Self{
        .input = input,
        .position = 0,
    };

    return instance;
}

test "Bool" {
    const expression: []const u8 =
        \\"True" / "False"
    ;

    const allocator = testing.allocator;
    const tokenizer: *Self = try Self.new(expression, allocator);
    const result: []const Token = try tokenizer.tokenize(allocator);

    try testing.expect(std.mem.eql(u8, result[0].literal, "True"));
    try testing.expect(std.mem.eql(u8, result[2].literal, "True"));
}
