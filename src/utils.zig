pub const Span = struct { start: usize, end: usize };

pub fn Spanned(comptime A: type) type {
    return struct {
        node: A,
        start: usize,
        end: usize,

        pub fn new(node: A, span: Span) @This() {
            return @This(){ .node = node, .start = span.start, .end = span.end };
        }

        pub fn get_span(self: @This()) Span {
            return Span{ .start = self.start, .end = self.end };
        }

        pub fn map(self: @This(), comptime B: type, f: fn (A) B) Spanned(B) {
            return @This(){ .node = f(self.node), .start = self.start, .end = self.end };
        }
    };
}

pub fn Result(comptime O: type, comptime E: type) type {
    return union(enum) {
        okay: O,
        err: E,

        pub fn new_okay(okay: O) @This() {
            return @This(){ .okay = okay };
        }

        pub fn new_err(err: E) @This() {
            return @This(){ .err = err };
        }

        pub fn map(self: @This(), comptime S2: type, f: fn (O) S2) Result(S2, E) {
            return switch (self) {
                .okay => |o| @This(){ .okay = f(o) },
                .err => |e| @This(){ .err = e },
            };
        }

        pub fn unwrap(self: @This()) O {
            return switch (self) {
                .okay => |o| o,
                .err => @panic("Unwrapped an error"),
            };
        }
    };
}
