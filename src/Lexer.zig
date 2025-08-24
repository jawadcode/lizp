const std = @import("std");
const char = std.ascii;
pub const Span = @import("utils.zig").Span;
pub const SExp = @import("sexp.zig").SExp;
const SExpInner = @import("sexp.zig").SExpInner;

const Lexer = @This();

source: []const u8,
cursor: usize,
eof: bool,

pub const Token = @import("utils.zig").Spanned(TokenKind);

pub const TokenKind = enum { lparen, rparen, number, symbol, string, eof, invalid };

pub fn new(source: []const u8) Lexer {
    return Lexer{ .source = source, .cursor = 0, .eof = false };
}

pub fn next(lexer: *Lexer) ?Token {
    lexer.skipWhitespace();

    if (lexer.isAtEnd()) {
        if (lexer.eof) {
            return null;
        } else {
            lexer.eof = true;
            return Token{ .node = .eof, .start = lexer.source.len, .end = lexer.source.len };
        }
    }

    const start = lexer.cursor;

    const c = lexer.nextChar();
    if (char.isAlphabetic(c) or c == '_') {
        return Token{ .node = lexer.ident(), .start = start, .end = lexer.cursor };
    } else if (char.isDigit(c)) {
        return Token{ .node = lexer.number(), .start = start, .end = lexer.cursor };
    } else switch (c) {
        '(' => return Token{ .node = .lparen, .start = start, .end = lexer.cursor },
        ')' => return Token{ .node = .rparen, .start = start, .end = lexer.cursor },
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
    while (true) {
        if (lexer.peek()) |ch| {
            switch (ch) {
                ';' => {
                    lexer.cursor += 1;
                    while (!lexer.isAtEnd() and lexer.peek().? != '\n') : (lexer.cursor += 1) {}
                },
                else => |c| if (char.isWhitespace(c)) {
                    lexer.cursor += 1;
                } else {
                    return;
                },
            }
        } else {
            return;
        }
    }
}

fn isAtEnd(lexer: *Lexer) bool {
    return lexer.cursor == lexer.source.len;
}

inline fn nextChar(lexer: *Lexer) u8 {
    const current = lexer.source[lexer.cursor];
    lexer.cursor += 1;
    return current;
}

inline fn peek(lexer: *Lexer) ?u8 {
    if (lexer.cursor == lexer.source.len) {
        return null;
    } else {
        return lexer.source[lexer.cursor];
    }
}
