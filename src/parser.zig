//! zigpeg Parser

const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const Self = @This();

original_expression: []const u8,

pub fn new(expression: []const u8) Self {
    return Self{ .original_expression = expression };
}

pub fn parse(self: Self, from: []const u8, comptime to: type) ParseError!to {
    _ = self.original_expression;

    if (mem.eql(u8, from, "True")) {
        return to{ .inner = .true };
    }

    if (mem.eql(u8, from, "False")) {
        return to{ .inner = .false };
    }

    return ParseError.TODO;
}

pub const ParseError = error{
    TODO,
};

test "boolean_parser" {
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
    const true_text: []const u8 = "True";
    std.debug.print("true_text: {s}\n", .{true_text});
    const false_text: []const u8 = "False";
    std.debug.print("false_text: {s}\n", .{false_text});

    // Parser
    const parser: Self = Self.new(expression);

    // Result
    const true_result = try parser.parse(true_text, boolean);
    try testing.expect(true_result.inner == .true);
    const false_result = try parser.parse(false_text, boolean);
    try testing.expect(false_result.inner == .false);
}
