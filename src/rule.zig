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

name: []const u8,
expression: Expression,

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    switch (self.expression) {
        .choice => |choices| allocator.free(choices),
        .sequence => |seq| allocator.free(seq),
        else => {},
    }
    allocator.free(self.name);
}

/// Creates a Rule
pub fn new(expression: []const u8, allocator: std.mem.Allocator) !Self {
    const arrow_idx = std.mem.indexOf(u8, expression, "<-") orelse return error.InvalidSyntax;
    const name_trim = std.mem.trim(u8, expression[0..arrow_idx], " \t\r\n");
    const name = try allocator.dupe(u8, name_trim);

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
    const gpa = std.heap.page_allocator;

    const rule = try Self.new(expression, gpa);
    defer rule.deinit(gpa);

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
    const gpa = std.heap.page_allocator;

    const rule = try Self.new(expression, gpa);
    defer rule.deinit(gpa);

    try testing.expect(std.mem.eql(u8, rule.name, "BooleanWithNull"));

    // Optional extra check: both literals exist
    switch (rule.expression) {
        .choice => |alts| {
            try testing.expect(alts.len == 3);

            switch (alts[0]) {
                .literal => {
                    try testing.expect(std.mem.eql(u8, alts[0].literal, "True"));
                },
                else => return error.UnexpectedExpressionType,
            }
        },
        else => unreachable,
    }
}

test "Parenthesis" {
    const expression: []const u8 =
        \\Parenthesis <- { "(" ")" }
    ;
    const gpa = std.heap.page_allocator;

    const rule = try Self.new(expression, gpa);
    defer rule.deinit(gpa);

    try testing.expect(std.mem.eql(u8, rule.name, "Parenthesis"));

    // Optional extra check: both literals exist
    switch (rule.expression) {
        .sequence => |alts| {
            try testing.expect(std.mem.eql(u8, alts[0].literal, "("));
            try testing.expect(std.mem.eql(u8, alts[1].literal, ")"));

            std.debug.print("alts.len: {d}", .{alts.len});
            try testing.expect(alts.len == 2);
        },
        else => unreachable,
    }
}
