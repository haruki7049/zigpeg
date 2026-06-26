//! Main entry point for the zigpeg library.

const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const Rule = @import("rule.zig");

/// Parses the program input according to the provided expression string, returning a value of type T.
pub fn parse(comptime T: type, program: []const u8, expression: []const u8) !T {
    _ = program;
    _ = expression;

    // const rule: Rule = Rule.new(expression);
}

test "Import tests in modules" {
    _ = @import("rule.zig");
}

// test "boolean" {
//     // boolean
//     const Boolean = struct {
//         inner:
//     };
//
//     // Expression
//     const expression: []const u8 =
//         \\Bool <- { "True" / "False" }
//     ;
//
//     std.debug.print("expression: {s}\n", .{expression});
//
//     // Text
//     const true_text: []const u8 = "True";
//     std.debug.print("true_text: {s}\n", .{true_text});
//     const false_text: []const u8 = "False";
//     std.debug.print("false_text: {s}\n", .{false_text});
//
//     // Result
//     const true_result = try parse(true_text, expression);
//     try testing.expect(true_result.inner == .true);
//     const false_result = try parse(false_text, expression);
//     try testing.expect(false_result.inner == .false);
// }
