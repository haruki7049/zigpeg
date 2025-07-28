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

    const result = try parse_recurse(tokens);
    std.debug.print("{any}\n", .{result});

    @panic("TODO");
}

fn parse_recurse(tokens: []const Token) !Expression {
    const left: Expression = switch_literal_reference(tokens[0]);
    const symbol: Symbol = tokens[1].symbol;
    const right: Expression = switch_literal_reference(tokens[2]);

    switch (symbol) {
        .choice => return Expression{ .choice = &[_]Expression{
            left,
            right,
        } },
        .sequence => return Expression{ .sequence = &[_]Expression{
            left,
            right,
        } },

        else => {
            std.debug.print("{any}, {any}, {any}\n", .{left, symbol, right});
            unreachable;
        }
    }
}

fn switch_literal_reference(token: Token) Expression {
    switch (token) {
        .literal => return Expression{ .literal = token.literal },

        else => @panic("Unexpected symbol"),
    }
}
