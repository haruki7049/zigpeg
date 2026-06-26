//! A Rule definition.
//! ```
//! Bool <- { "True" / "False" }
//! ```

const std = @import("std");
const testing = std.testing;

const Self = @This();
const Parser = @import("rule/parser.zig");
const Expression = Parser.Expression;
const ArrayList = std.ArrayList;

/// The name of the rule.
name: []const u8,
/// The parsed expression of the rule.
expression: Expression,

/// Creates a new Rule instance from a string expression.
pub fn new(expression: []const u8, allocator: std.mem.Allocator) !Self {
    const arrow_idx = std.mem.indexOf(u8, expression, "<-") orelse return error.InvalidSyntax;
    const name = std.mem.trim(u8, expression[0..arrow_idx], " \t\r\n");

    // ── expression string inside '{ }' ─────────────────────
    const brace_start = std.mem.indexOfScalar(u8, expression, '{') orelse return error.InvalidSyntax;
    const brace_end = std.mem.lastIndexOfScalar(u8, expression, '}') orelse return error.InvalidSyntax;
    const inner = std.mem.trim(u8, expression[brace_start + 1 .. brace_end], " \t\r\n");

    var parser = Parser{ .input = inner };
    const expr = try parser.parse(allocator);

    return Self{
        .name = name,
        .expression = expr,
    };
}

test "Import tests in modules" {
    _ = @import("rule/tokenizer.zig");
    _ = @import("rule/parser.zig");
}

test "Bool" {
    const expression: []const u8 =
        \\Bool <- { "True" / "False" }
    ;

    const allocator = std.heap.page_allocator;
    const rule = try Self.new(expression, allocator);

    try testing.expect(std.mem.eql(u8, rule.name, "Bool"));

    // Optional extra check: both literals exist
    switch (rule.expression) {
        .choice => |alts| {
            try testing.expect(std.mem.eql(u8, alts[0].literal, "True"));
            try testing.expect(std.mem.eql(u8, alts[1].literal, "False"));
            try testing.expect(alts.len == 2);
        },
        else => unreachable,
    }
}

test "BoolWithNull" {
    const expression: []const u8 =
        \\BooleanWithNull <- { "True" / "False" / "Null" }
    ;

    const allocator = std.heap.page_allocator;
    const rule = try Self.new(expression, allocator);

    try testing.expect(std.mem.eql(u8, rule.name, "BooleanWithNull"));

    // Optional extra check: both literals exist
    switch (rule.expression) {
        .choice => |alts| {
            std.debug.print("alts.len: {d}", .{alts.len});
            try testing.expect(alts.len == 3);

            switch (alts[0]) {
                .literal => {
                    try testing.expect(std.mem.eql(u8, alts[0].literal, "True"));
                    try testing.expect(std.mem.eql(u8, alts[1].literal, "False"));
                    try testing.expect(std.mem.eql(u8, alts[2].literal, "Null"));
                },
                else => return error.UnexpectedExpressionType,
            }
        },
        else => unreachable,
    }
}

test "Parenthesis" {
    const expression: []const u8 =
        \\Parenthesis <- { "(" ~ ")" }
    ;

    const allocator = std.heap.page_allocator;
    const rule = try Self.new(expression, allocator);

    try testing.expect(std.mem.eql(u8, rule.name, "Parenthesis"));

    // Optional extra check: both literals exist
    switch (rule.expression) {
        .sequence => |alts| {
            try testing.expect(std.mem.eql(u8, alts[0].literal, "("));
            try testing.expect(std.mem.eql(u8, alts[1].literal, ")"));
            try testing.expect(alts.len == 2);
        },
        else => unreachable,
    }
}
