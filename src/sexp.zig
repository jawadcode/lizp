const std = @import("std");

const Spanned = @import("utils.zig").Spanned;

pub const SExp = Spanned(SExpInner);

const INDENT_WIDTH = 2;

pub const SExpInner = union(enum) {
    int: i32,
    string: []const u8,
    @"var": []const u8,
    list: std.ArrayList(SExp),

    pub fn format_sexp(self: @This(), alloc: std.mem.Allocator) !std.ArrayList(u8) {
        var buf = std.ArrayList(u8).init(alloc);
        const writer = buf.writer();
        try self.fmt_sexp(writer, 0);
        return buf;
    }

    fn fmt_sexp(self: @This(), writer: anytype, indent: usize) !void {
        _ = try writer.writeByteNTimes(' ', INDENT_WIDTH * indent);

        switch (self) {
            .int => |num| try std.fmt.format(writer, "{d}", .{num}),
            .string => |string| {
                _ = try writer.writeByte('"');
                _ = try writer.write(string);
                _ = try writer.writeByte('"');
            },
            .@"var" => |ident| _ = try writer.write(ident),
            .list => |list| {
                _ = try writer.writeByte('(');
                try list.items[0].node.fmt_sexp(writer, 0);
                for (list.items[1..]) |sexp| {
                    _ = try writer.write("\n ");
                    try sexp.node.fmt_sexp(writer, indent);
                }
                _ = try writer.writeByte(')');
            },
        }
    }
};
