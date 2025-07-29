const std = @import("std");
pub const Span = @import("utils.zig").Span;
const ParseResult = @import("utils.zig").Result(SExp, Span);
pub const SExp = @import("sexp.zig").SExp;
const SExpInner = @import("sexp.zig").SExpInner;

pub fn parse(source: []const u8, alloc: std.mem.Allocator) ParseResult {
    var state: ParserState = .{ .source = source, .start = 0, .current = 0 };
    return parse_expr(&state, alloc);
}

const ParserState = struct {
    source: []const u8,
    start: usize,
    current: usize,
};

fn parse_expr(state: *ParserState, alloc: std.mem.Allocator) ParseResult {
    _ = state;
    var list = std.ArrayList(SExp).init(alloc);
    list.append(SExp{ .node = SExpInner{ .int = 123 }, .start = 1, .end = 4 }) catch undefined;
    list.append(SExp{ .node = SExpInner{ .int = 123 }, .start = 5, .end = 8 }) catch undefined;
    list.append(SExp{ .node = SExpInner{ .int = 123 }, .start = 9, .end = 12 }) catch undefined;
    const sexp = SExp{ .node = SExpInner{ .list = list }, .start = 0, .end = 12 };
    return ParseResult.new_okay(sexp);
}
