const std = @import("std");
const lib = @import("default_lib");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const source = "(123 123 123)";
    const output = lib.parser.parse(source, allocator)
        .unwrap()
        .node
        .format_sexp(allocator) catch unreachable;
    std.log.info("Input: {s}\nOutput:\n{s}", .{ source, output.items });
}
