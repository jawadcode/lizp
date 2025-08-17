const std = @import("std");
pub const Span = @import("utils.zig").Span;
pub const Spanned = @import("utils.zig").Spanned;
pub const SExp = @import("sexp.zig").SExp;
const SExpInner = @import("sexp.zig").SExpInner;
const Lexer = @import("Lexer.zig");

// String is a message describing the expected token
const ParseError = Spanned([]const u8);

const ParseResult = @import("utils.zig").Result(SExp, ParseError);
const PeekLexer = @import("utils.zig").PeekIter(Lexer, Lexer.Token);

const Parser = @This();

lexer: PeekLexer,

pub fn new(source: []const u8) Parser {
    return Parser{ .lexer = PeekLexer.new(Lexer.new(source)) };
}

pub fn next(parser: *Parser, alloc: std.mem.Allocator) ParseResult {
    const peeked = parser.peek();
    const start_tok = parser.lexer.next().?;
    switch (peeked) {
        .number => {
            const tok_src = parser.text(start_tok);
            return ParseResult.new_okay(SExp{ .node = SExpInner{ .int = std.fmt.parseInt(i64, tok_src, 10) catch unreachable }, .start = start_tok.start, .end = start_tok.end });
        },
        .symbol => {
            const tok_src = parser.text(start_tok);
            return ParseResult.new_okay(SExp{ .node = SExpInner{ .@"var" = tok_src }, .start = start_tok.start, .end = start_tok.end });
        },
        .string => {
            const str = parser.text(start_tok);
            // str = str[1..(str.len - 1)];

            var str_res = std.ArrayList(u8).initCapacity(alloc, str.len - 2) catch @panic("OOM");

            var index: usize = 1;
            var escaped = false;
            while (str[index] != '"' or (escaped and str[index] == '"')) : (index += 1) {
                if (escaped) {
                    switch (str[index]) {
                        'n' => str_res.append('\n') catch @panic("OOM"),
                        'r' => str_res.append('\r') catch @panic("OOM"),
                        't' => str_res.append('\t') catch @panic("OOM"),
                        '"' => str_res.append('"') catch @panic("OOM"),
                        '\\' => str_res.append('\\') catch @panic("OOM"),
                        else => return ParseResult.new_err(ParseError{ .node = "'n', 'r', 't', '\"' or '\\'", .start = start_tok.start + index, .end = start_tok.start + index + 1 }),
                    }
                    escaped = false;
                } else if (str[index] == '\\') {
                    escaped = true;
                } else {
                    str_res.append(str[index]) catch @panic("OOM");
                }
            }

            return ParseResult.new_okay(SExp{ .node = SExpInner{ .string = str_res }, .start = start_tok.start, .end = start_tok.end });
        },
        .lparen => {
            var exprs = std.ArrayList(SExp).init(alloc);
            while (parser.peek() != .rparen) {
                switch (parser.next(alloc)) {
                    .okay => |o| exprs.append(o) catch @panic("OOM"),
                    .err => |e| return ParseResult.new_err(e),
                }
            }
            const rparen = parser.lexer.next().?;
            return ParseResult.new_okay(SExp{ .node = SExpInner{ .list = exprs }, .start = start_tok.start, .end = rparen.end });
        },
        else => return ParseResult.new_err(ParseError{ .node = "number, symbol, string or '('", .start = start_tok.start, .end = start_tok.end }),
    }
}

fn peek(parser: *Parser) Lexer.TokenKind {
    return if (parser.lexer.peek()) |peeked| peeked.node else .eof;
}

fn text(parser: *Parser, tok: Lexer.Token) []const u8 {
    return parser.lexer.inner.source[tok.start..tok.end];
}
