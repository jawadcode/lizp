const std = @import("std");
const char = std.ascii;
pub const Span = @import("utils.zig").Span;
pub const SExp = @import("sexp.zig").SExp;
const SExpInner = @import("sexp.zig").SExpInner;

const Lexer = @This();

source: []const u8,
cursor: usize,

pub const Token = @import("utils.zig").Spanned(TokenKind);

pub const TokenKind = enum { lparen, rparen, number, symbol, string, eof, invalid };

pub fn new(source: []const u8) Lexer {
    return Lexer{ .source = source, .cursor = 0 };
}

pub fn next(lexer: *Lexer) ?Token {
    lexer.skipWhitespace();
    if (lexer.isAtEnd()) return Token{ .node = .eof, .start = lexer.source.len, .end = lexer.source.len };

    const start = lexer.cursor;

    const c = lexer.current();
    if (char.isAlphabetic(c) or c == '_') {
        return Token{ .node = lexer.ident(), .start = start, .end = lexer.cursor };
    } else if (char.isDigit(c)) {
        return Token{ .node = lexer.number(), .start = start, .end = lexer.cursor };
    } else switch (c) {
        '(' => return Token{ .node = .lparen, .start = start, .end = lexer.cursor + 1 },
        ')' => return Token{ .node = .rparen, .start = start, .end = lexer.cursor + 1 },
        '"' => {
            lexer.cursor += 1;
            var escaped = false;
            while (!lexer.isAtEnd()) : (lexer.cursor += 1) {
                if (lexer.peek() == '\\') {
                    escaped = true;
                } else if (escaped) {
                    escaped = false;
                } else if (lexer.peek() == '"') {
                    break;
                }
            }

            // Either we reached the end of the input or a closing quote
            if (lexer.isAtEnd()) {
                return Token{ .node = .invalid, .start = lexer.source.len, .end = lexer.source.len };
            } else {
                lexer.cursor += 1;
                return Token{
                    .node = .string,
                    .start = start,
                    .end = lexer.cursor,
                };
            }
        },
        else => return Token{ .node = .invalid, .start = start, .end = lexer.cursor },
    }
}

fn ident(lexer: *Lexer) TokenKind {
    while (!lexer.isAtEnd() and
        (char.isAlphabetic(lexer.peek().?) or
            lexer.peek() == '_' or
            char.isDigit(lexer.peek().?))) : (lexer.cursor += 1)
    {}

    return .symbol;
}

fn number(lexer: *Lexer) TokenKind {
    while (!lexer.isAtEnd() and char.isDigit(lexer.peek().?)) : (lexer.cursor += 1) {}

    return .number;
}

fn skipWhitespace(lexer: *Lexer) void {
    while (lexer.cursor < lexer.source.len and
        char.isWhitespace(lexer.current())) : (lexer.cursor += 1)
    {}
}

fn isAtEnd(lexer: *Lexer) bool {
    return lexer.cursor == lexer.source.len - 1;
}

inline fn current(lexer: *Lexer) u8 {
    return lexer.source[lexer.cursor];
}

inline fn nextChar(lexer: *Lexer) u8 {
    lexer.cursor += 1;
    return lexer.source[lexer.cursor];
}

inline fn peek(lexer: *Lexer) ?u8 {
    if (lexer.current() == (lexer.source.len - 1)) {
        return null;
    } else {
        return lexer.source[lexer.cursor];
    }
}
