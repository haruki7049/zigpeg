//! A Rule definition.
//! ```
//! Bool <- { "True" / "False" }
//! ```

const std = @import("std");
const testing = std.testing;

const Self = @This();
const ArrayList = std.ArrayList;

name: []const u8,
expression: Expression,

const Expression = union(enum) {
    literal: []const u8,
    reference: []const u8,
    choice: []const Expression,
    sequence: []const Expression,
};

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

    // ── split by '/' to build a choice list ────────────────
    var parts_iter = std.mem.splitScalar(u8, inner, '/');
    var expr_buf = ArrayList(Expression).init(allocator);

    parts_iter.reset();
    var i: usize = 0;
    while (parts_iter.next()) |part| {
        var lit_trim = std.mem.trim(u8, part, "\t\r\n\"");
        lit_trim = std.mem.trimLeft(u8, lit_trim, "\" ");
        lit_trim = std.mem.trimRight(u8, lit_trim, "\" ");

        try expr_buf.append(Expression{ .literal = lit_trim });
        i += 1;
    }

    return Self{
        .name = name,
        .expression = Expression{ .choice = expr_buf.items },
    };
}

const arrow: []const u8 = "<-";
const quotation: u8 = '"';
const left_brace: u8 = '{';
const right_brace: u8 = '}';
const slash: u8 = '/';
const backslash: u8 = '\\';

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
            try testing.expect(std.mem.eql(u8, alts[0].literal, "True"));
            try testing.expect(std.mem.eql(u8, alts[1].literal, "False"));
            try testing.expect(std.mem.eql(u8, alts[2].literal, "Null"));

            // std.debug.print("alts.len: {d}", .{alts.len});
            try testing.expect(alts.len == 3);
        },
        else => unreachable,
    }
}

//test "Parenthesis" {
//    const expression: []const u8 =
//        \\Parenthesis <- { "(" ")" }
//    ;
//    const gpa = std.heap.page_allocator;
//
//    const rule = try Self.new(expression, gpa);
//    defer rule.deinit(gpa);
//
//    try testing.expect(std.mem.eql(u8, rule.name, "Parenthesis"));
//
//    // Optional extra check: both literals exist
//    switch (rule.expression) {
//        .sequence => |alts| {
//            try testing.expect(std.mem.eql(u8, alts[0].literal, "("));
//            try testing.expect(std.mem.eql(u8, alts[1].literal, ")"));
//
//            std.debug.print("alts.len: {d}", .{alts.len});
//            try testing.expect(alts.len == 2);
//        },
//        else => unreachable,
//    }
//}
