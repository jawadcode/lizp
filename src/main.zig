const std = @import("std");
const Parser = @import("default_lib").Parser;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const source = "123";
    var parser = Parser.new(source);
    const output = parser
        .next(alloc)
        .unwrap()
        .node
        .format_sexp(alloc) catch unreachable;
    std.log.info("Input: {s}\nOutput:\n{s}", .{ source, output.items });
}
