const std = @import("std");

const Spanned = @import("utils.zig").Spanned;

pub const SExp = Spanned(SExpInner);
const SExpInner = union(enum) {
    int: i32,
    string: []const u8,
    @"var": []const u8,
    list: std.ArrayList(SExp),
};

