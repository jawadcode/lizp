const std = @import("std");
pub const Span = @import("utils.zig").Span;
pub const SExp = @import("sexp.zig").SExp;
const SExpInner = @import("sexp.zig").SExpInner;
const Lexer = @import("Lexer.zig");

const ParseResult = @import("utils.zig").Result(SExp, Span);
const PeekLexer = @import("utils.zig").PeekIter(Lexer, Lexer.Token);

const Parser = @This();

lexer: PeekLexer,

pub fn new(source: []const u8) Parser {
    return Parser{ .lexer = PeekLexer.new(Lexer.new(source)) };
}

pub fn next(parser: *Parser, alloc: std.mem.Allocator) ParseResult {
    _ = alloc;
    switch (parser.lexer.peek().node) {
        .number => |_| {
            _ = parser.lexer.next();
            return ParseResult.new_okay(SExp{ .node = SExpInner{ .int = 123 }, .start = 0, .end = 3 });
        },
        else => unreachable,
    }
}
