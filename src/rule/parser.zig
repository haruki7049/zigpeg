const std = @import("std");
const ArrayList = std.ArrayList;
const Self = @This();

const Token = union(enum) {
    literal: []const u8,
    reference: []const u8,
    symbol: u8, // '/', '~', '(', ')', etc.
};

pub const Expression = union(enum) {
    literal: []const u8,
    reference: []const u8,
    choice: []const Expression,
    sequence: []const Expression,
};

input: []const u8,
pos: usize = 0,

pub fn next(self: *Self) ?u8 {
    while (self.pos < self.input.len and std.ascii.isWhitespace(self.input[self.pos])) {
        self.pos += 1;
    }
    if (self.pos >= self.input.len) return null;
    const c = self.input[self.pos];
    self.pos += 1;
    return c;
}

pub fn peek(self: *Self) ?u8 {
    var i = self.pos;
    while (i < self.input.len and std.ascii.isWhitespace(self.input[i])) : (i += 1) {}
    if (i >= self.input.len) return null;
    return self.input[i];
}

pub fn parse(self: *Self, allocator: std.mem.Allocator) !Expression {
    var left = try self.parseSequence(allocator);

    while (self.peek()) |c| {
        if (c == '/') {
            _ = self.next();
            const right = try self.parseSequence(allocator);
            left = try makeChoice(allocator, &[_]Expression{ left, right });
        } else {
            break;
        }
    }

    return left;
}

pub fn parseSequence(self: *Self, allocator: std.mem.Allocator) !Expression {
    var parts = ArrayList(Expression).init(allocator);
    defer if (parts.items.len == 1) allocator.free(parts.items);

    while (self.peek()) |c| {
        if (c == '/' or c == '}') break;
        const expr = try self.parsePrimary();
        try parts.append(expr);
    }

    if (parts.items.len == 1) {
        return parts.pop().?;
    }

    return Expression{ .sequence = try parts.toOwnedSlice() };
}

pub fn parsePrimary(self: *Self) !Expression {
    const c = self.peek() orelse return error.UnexpectedEOF;

    if (c == '"') {
        _ = self.next(); // consume opening quote
        const start = self.pos;
        while (self.pos < self.input.len and self.input[self.pos] != '"') {
            self.pos += 1;
        }
        if (self.pos >= self.input.len) return error.UnterminatedLiteral;
        const lit = self.input[start..self.pos];
        self.pos += 1; // consume closing quote
        return Expression{ .literal = lit };
    } else {
        // parse reference or symbol
        const start = self.pos;
        while (self.pos < self.input.len and std.ascii.isAlphabetic(self.input[self.pos])) {
            self.pos += 1;
        }
        const name = self.input[start..self.pos];
        return Expression{ .reference = name };
    }
}

fn makeChoice(allocator: std.mem.Allocator, items: []const Expression) !Expression {
    const buf = try allocator.alloc(Expression, items.len);
    @memcpy(buf, items);
    return Expression{ .choice = buf };
}
