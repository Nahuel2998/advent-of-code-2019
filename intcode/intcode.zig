const std = @import("std");

const Self = @This();

code: []const Word,

pub const Word = i64;

const Op = enum (u32) {
    add = 1,
    mul,
    in,
    out,
    jnz,
    jz,
    lt,
    eq,
    rbo,
    halt = 99,
};

const ParameterMode = enum {
    position,
    immediate,
    relative,

    fn of(modes: Word, idx: usize) ParameterMode {
        return @enumFromInt(@rem(@divTrunc(modes, std.math.pow(Word, 10, @intCast(idx))), 10));
    }
};

pub const Input = struct {
    buf: *std.ArrayList(Word),
    i:    usize = 0,

    fn read(self: *Input) !Word {
        if (self.i >= self.buf.items.len) {
            return error.AwaitingInput;
        }
        const res = self.buf.items[self.i];
        self.i += 1;
        return res;
    }
};
pub const Output = struct {
    buf:      *std.ArrayList(Word),   
    allocator: std.mem.Allocator,

    fn write(self: *Output, value: Word) !void {
        try self.buf.append(self.allocator, value);
    }
};

pub const RunContext = struct {
    code: []Word,
    ip:     u32  = 0,
    rb:     Word = 0,

    stdin:  ?Input  = null,
    stdout: ?Output = null,

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, code: []const Word) !RunContext {
        const copy = try allocator.dupe(Word, code);
        return .{ .code = copy, .allocator = allocator };
    }

    pub fn deinit(self: RunContext) void {
        self.allocator.free(self.code);
    }

    // Access self.code allowing oob
    fn mem(self: *RunContext, idx: usize) !*Word {
        const len = self.code.len;
        if (idx >= len) {
            self.code = try self.allocator.realloc(self.code, idx + 1);
            @memset(self.code[len..], 0);
        }
        return &self.code[idx];
    }

    fn step(self: *RunContext) !bool {
        if (self.ip >= self.code.len) return error.NoHalt;

        const pms = @divTrunc(self.code[self.ip], 100);
        const op: Op = @enumFromInt(@rem(self.code[self.ip], 100));
        switch (op) {
            .add => { // add,a,b,res
                const a   = try self.param(pms, 0);
                const b   = try self.param(pms, 1);
                const res = try self.lparam(pms, 2);
                res.* = a + b;
                self.ip += 4;
            },
            .mul => { // mul,a,b,res
                const a   = try self.param(pms, 0);
                const b   = try self.param(pms, 1);
                const res = try self.lparam(pms, 2);
                res.* = a * b;
                self.ip += 4;
            },
            .in => { // in,res
                const res = try self.lparam(pms, 0);
                res.* = try self.stdin.?.read();
                self.ip += 2;
            },
            .out => { // out,a
                const a = try self.param(pms, 0);
                try self.stdout.?.write(a);
                self.ip += 2;
            },
            .jnz => { // jnz,a,b
                const a = try self.param(pms, 0);
                if (a != 0) {
                    const b = try self.param(pms, 1);
                    self.ip = @intCast(b);
                } else {
                    self.ip += 3;
                }
            },
            .jz => { // jz,a,b
                const a = try self.param(pms, 0);
                if (a == 0) {
                    const b = try self.param(pms, 1);
                    self.ip = @intCast(b);
                } else {
                    self.ip += 3;
                }
            },
            .lt => { // lt,a,b,res
                const a   = try self.param(pms, 0);
                const b   = try self.param(pms, 1);
                const res = try self.lparam(pms, 2);
                res.* = @intFromBool(a < b);
                self.ip += 4;
            },
            .eq => { // eq,a,b,res
                const a   = try self.param(pms, 0);
                const b   = try self.param(pms, 1);
                const res = try self.lparam(pms, 2);
                res.* = @intFromBool(a == b);
                self.ip += 4;
            },
            .rbo => { // rbo,a
                const a = try self.param(pms, 0);
                self.rb += a;
                self.ip += 2;
            },
            .halt => {
                return false;
            },
        }
        return true;
    }

    fn param(self: *RunContext, modes: Word, idx: usize) !Word {
        const pmode = ParameterMode.of(modes, idx);
        const arg   = self.code[self.ip + idx + 1];
        return switch (pmode) {
            .immediate =>                         arg,
            .position  => (try self.mem( @intCast(arg) )).*,
            .relative  => (try self.mem( @intCast(arg + self.rb) )).*,
        };
    }

    fn lparam(self: *RunContext, modes: Word, idx: usize) !*Word {
        const pmode = ParameterMode.of(modes, idx);
        const arg   = self.code[self.ip + idx + 1];
        return switch (pmode) {
            .immediate => unreachable,
            .position  => try self.mem( @intCast(arg) ),
            .relative  => try self.mem( @intCast(arg + self.rb) ),
        };
    }

    pub fn run(self: *RunContext) !void {
        while (self.ip < self.code.len) {
            if (!try self.step()) break;
        }
    }
};

pub fn init(allocator: std.mem.Allocator, input: []const u8) !Self {
    var code: std.ArrayList(Word) = .empty;
    var it = std.mem.tokenizeScalar(u8, std.mem.trimEnd(u8, input, " \n"), ',');
    while (it.next()) |int| {
        try code.append(allocator, try std.fmt.parseInt(Word, int, 10));
    }
    return .{ .code = code.items };
}

pub fn run(self: Self, allocator: std.mem.Allocator, stdin: ?Input, stdout: ?Output) !RunContext {
    var ctx = try self.newContext(allocator);
    ctx.stdin  = stdin;
    ctx.stdout = stdout;
    try ctx.run();
    return ctx;
}

pub fn newContext(self: Self, allocator: std.mem.Allocator) !RunContext {
    return try RunContext.init(allocator, self.code);
}
