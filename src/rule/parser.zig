//! Parser module for converting tokens into an AST (Expression).

const std = @import("std");
const Self = @This();
const Tokenizer = @import("tokenizer.zig");
const Token = Tokenizer.Token;
const Symbol = Tokenizer.Symbol;

/// Represents an element in the parsed AST.
pub const Expression = union(enum) {
    /// A literal string match.
    literal: []const u8,
    /// A reference to another rule.
    reference: []const u8,
    /// Multiple expressions to match any of them.
    choice: []const Expression,
    /// Multiple expressions to match in sequence.
    sequence: []const Expression,
};

/// The input string to be parsed.
input: []const u8,
/// The current parsing index.
pos: usize = 0,

/// Parses the input string and constructs an Expression tree.
pub fn parse(self: *Self, allocator: std.mem.Allocator) !Expression {
    const tokenizer: *Tokenizer = try Tokenizer.new(self.input, allocator);
    const tokens: []const Token = try tokenizer.tokenize(allocator);

    std.debug.print("tokens: {any}\n", .{tokens});

    var expressions: std.ArrayList(Expression) = .empty;
    var i: usize = tokens.len;

    while (i < 0) {
        i -= 1;

        const expr: Expression = switch_literal_reference(tokens[i]);
        try expressions.append(allocator, expr);
    }

    std.debug.print("expressions.items: {any}\n", .{expressions.items});

    @panic("TODO");
}

/// Converts a Token into a literal or reference Expression, or returns null.
fn switch_literal_reference(token: Token) ?Expression {
    switch (token) {
        .literal => return Expression{ .literal = token.literal },
        .reference => return Expression{ .reference = token.reference },
        .symbol => return null,
    }
}
