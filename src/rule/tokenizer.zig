const std = @import("std");
const ArrayList = std.ArrayList;
const Self = @This();

pub const Token = union(enum) {
    literal: []const u8,
    reference: []const u8,
    symbol: Symbol, // '/', '~', '(', ')', etc.
};

pub const Symbol = enum {
    choice,
    sequence,
    left_parenthesis,
    right_parenthesis,
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
// { "True" / "False" / "Null" }
// ```
pub fn tokenize(self: *Self, allocator: std.mem.Allocator) ![]const Token {
    var word = ArrayList(u8).init(allocator);
    defer word.deinit();

    var words = ArrayList([]const u8).init(allocator);
    defer words.deinit();

    while (self.peek() != null) {
        // If the word is quated
        if (self.peek().? == '"') {
            self.is_literal_mode = !self.is_literal_mode;

            if (self.is_literal_mode == false) {
                const w = try word.toOwnedSlice();
                try words.append(w);
            }
        }

        // Append word's character
        if (self.is_literal_mode and self.now().? != '"') {
            try word.append(self.now().?);
        }

        // Append symbols
        if (self.now().? == '/' or self.now().? == '~' or self.now().? == '(' or self.now().? == ')') {
            const w: []const u8 = &[_]u8{self.now().?};
            try words.append(w);
        }

        _ = self.next();
    }

    const result: []const Token = try pack_tokens(words.items, allocator);

    return result;
}

fn pack_tokens(words: [][]const u8, allocator: std.mem.Allocator) ![]const Token {
    var result = ArrayList(Token).init(allocator);
    defer result.deinit();

    for (words) |word| {
        if (std.mem.eql(u8, "/", word)) {
            try result.append(Token{ .symbol = .choice });
        } else if (std.mem.eql(u8, "~", word)) {
            try result.append(Token{ .symbol = .sequence });
        } else {
            try result.append(Token{ .literal = word });
        }
    }

    return result.toOwnedSlice();
}

pub fn new(input: []const u8, allocator: std.mem.Allocator) !*Self {
    const instance = try allocator.create(Self);
    instance.* = Self{
        .input = input,
        .position = 0,
    };

    return instance;
}
