const std = @import("std");
const Lexer = @import("default_lib").Lexer;
const Parser = @import("default_lib").Parser;

const GPA = std.heap.GeneralPurposeAllocator(.{});

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

pub fn main() !void {
    var gpa = GPA{};
    const alloc = gpa.allocator();

    while (true) {
        try stdout.writeAll("=> ");

        var stdin_bufd = std.io.bufferedReader(stdin);
        var stdin_reader = stdin_bufd.reader();
        var line_buf: [2048]u8 = undefined;
        const line = (try stdin_reader.readUntilDelimiterOrEof(&line_buf, '\n')) orelse {
            try stdout.writeAll("\n");
            break;
        };

        if (line.len > 1 and line[0] == ':') {
            const rest = line[1..];
            if (std.mem.eql(u8, rest, "q") or std.mem.eql(u8, rest, "quit")) {
                try stdout.writeAll("Goodbye 👋\n");
                std.process.exit(0);
            }
        }

        try stdout.print("Input: \"{s}\"\n", .{line});

        // var lexer = Lexer.new(line);
        // var count: usize = 0;
        // while (count <= 100) : (count += 1) {
        //     if (lexer.next()) |tok| {
        //         try stdout.print("{d}-{d}: {s}\n", .{ tok.start, tok.end, @tagName(tok.node) });
        //     } else {
        //         break;
        //     }
        // }

        var parser = Parser.new(line, alloc);
        const sexp = parser.next();
        const output = switch (sexp) {
            .okay => |o| o.node.format_sexp(alloc) catch undefined,
            .err => |e| {
                try stderr.print("Error: Expected {s} @ {d}-{d}\n", .{ e.node, e.start, e.end });
                continue;
            },
        };

        try stdout.print("Output:\n{s}\n\n", .{output.items});
    }
}
