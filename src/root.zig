const std = @import("std");
const testing = std.testing;

pub const Parser = @import("parser.zig");

test "Import tests in modules" {
    _ = @import("parser.zig");
}
