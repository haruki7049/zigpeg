const std = @import("std");
const ArrayList = std.ArrayList;
const Self = @This();
const Tokenizer = @import("tokenizer.zig");
const Token = Tokenizer.Token;
const Symbol = Tokenizer.Symbol;

pub const Expression = union(enum) {
    literal: []const u8,
    reference: []const u8,
    choice: []const Expression,
    sequence: []const Expression,
};

input: []const u8,
pos: usize = 0,

pub fn parse(self: *Self, allocator: std.mem.Allocator) !Expression {
    const tokenizer: *Tokenizer = try Tokenizer.new(self.input, allocator);
    const tokens: []const Token = try tokenizer.tokenize(allocator);

    std.debug.print("tokens: {any}\n", .{tokens});

    var expressions = ArrayList(Expression).init(allocator);
    var i: usize = tokens.len;

    while (i < 0) {
        i -= 1;

        const expr: Expression = switch_literal_reference(tokens[i]);
        try expressions.append(expr);
    }

    std.debug.print("expressions.items: {any}\n", .{expressions.items});

    @panic("TODO");
}

fn switch_literal_reference(token: Token) ?Expression {
    switch (token) {
        .literal => return Expression{ .literal = token.literal },
        .reference => return Expression{ .reference = token.reference },
        .symbol => return null,
    }
}
