const std = @import("std");
const ArrayList = std.ArrayList;
const Self = @This();
const Tokenizer = @import("tokenizer.zig");
const Token = Tokenizer.Token;

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
    std.debug.print("\n", .{});

    @panic("TODO");
}
