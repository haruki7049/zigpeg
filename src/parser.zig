//! zigpeg Parser

const std = @import("std");
const testing = std.testing;
const Self = @This();

original_expression: []const u8,

pub fn new(expression: []const u8) Self {
    return Self{ .original_expression = expression };
}

pub fn parse(self: Self, text: []const u8, comptime to: type) !to {
    _ = self.original_expression;
    _ = text;

    @panic("TODO");
}

test "Parser" {
    // Example type for parsed result
    const boolean = struct {
        inner: enum {
            true,
            false,
        },
    };

    // Expression
    const expression: []const u8 =
        \\true <- "True"
        \\false <- "False"
        \\Bool <- { true / false }
    ;
    std.debug.print("expression: {s}\n", .{expression});

    // Text
    const text: []const u8 = "True";
    std.debug.print("text: {s}\n", .{text});

    // Parser
    const parser: Self = Self.new(expression);

    // Result
    const result = try parser.parse(text, boolean);
    try testing.expect(result.inner == .true);
}
