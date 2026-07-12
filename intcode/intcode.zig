const std = @import("std");

const Self = @This();

code: []const i64,

const Op = enum (u32) {
    add = 1,
    mul,
    in,
    out,
    jnz,
    jz,
    lt,
    eq,
    halt = 99,
};

const ParameterMode = enum {
    position,
    immediate,
};

pub const Input = struct {
    buf: *std.ArrayList(i64),
    i:    usize = 0,

    fn read(self: *Input) !i64 {
        if (self.i >= self.buf.items.len) {
            return error.AwaitingInput;
        }
        const res = self.buf.items[self.i];
        self.i += 1;
        return res;
    }
};
pub const Output = struct {
    buf:      *std.ArrayList(i64),   
    allocator: std.mem.Allocator,

    fn write(self: *Output, value: i64) !void {
        try self.buf.append(self.allocator, value);
    }
};

pub const RunContext = struct {
    ip:     u32,
    code: []i64,

    stdin:  ?Input  = null,
    stdout: ?Output = null,

    pub fn init(allocator: std.mem.Allocator, code: []const i64) !RunContext {
        const copy = try allocator.dupe(i64, code);
        return .{ .ip = 0, .code = copy };
    }

    // TODO: I don't like how self.ip is incremented
    fn step(self: *RunContext) !bool {
        if (self.ip >= self.code.len) return error.NoHalt;

        const param_modes = @divTrunc(self.code[self.ip], 100);
        const op: Op = @enumFromInt(@rem(self.code[self.ip], 100));
        switch (op) {
            .add => { // add,a,b,res
                const a = self.param(param_modes, 0);
                const b = self.param(param_modes, 1);
                self.lparam(2).* = a + b;
                self.ip += 4;
            },
            .mul => { // mul,a,b,res
                const a = self.param(param_modes, 0);
                const b = self.param(param_modes, 1);
                self.lparam(2).* = a * b;
                self.ip += 4;
            },
            .in => { // in,res
                self.lparam(0).* = try self.stdin.?.read();
                self.ip += 2;
            },
            .out => { // out,a
                const a = self.param(param_modes, 0);
                try self.stdout.?.write(a);
                self.ip += 2;
            },
            .jnz => { // jnz,a,b
                const a = self.param(param_modes, 0);
                if (a != 0) {
                    const b = self.param(param_modes, 1);
                    self.ip = @intCast(b);
                } else {
                    self.ip += 3;
                }
            },
            .jz => { // jz,a,b
                const a = self.param(param_modes, 0);
                if (a == 0) {
                    const b = self.param(param_modes, 1);
                    self.ip = @intCast(b);
                } else {
                    self.ip += 3;
                }
            },
            .lt => { // lt,a,b,res
                const a = self.param(param_modes, 0);
                const b = self.param(param_modes, 1);
                self.lparam(2).* = @intFromBool(a < b);
                self.ip += 4;
            },
            .eq => { // eq,a,b,res
                const a = self.param(param_modes, 0);
                const b = self.param(param_modes, 1);
                self.lparam(2).* = @intFromBool(a == b);
                self.ip += 4;
            },
            .halt => {
                self.ip += 1;
                return false;
            },
        }
        return true;
    }

    fn param(self: RunContext, modes: i64, idx: usize) i64 {
        const pmode: ParameterMode = @enumFromInt(@rem(@divTrunc(modes, std.math.pow(i64, 10, @intCast(idx))), 10));
        return switch (pmode) {
            .position  => self.code[@intCast(self.code[self.ip + idx + 1])],
            .immediate =>                    self.code[self.ip + idx + 1],
        };
    }

    fn lparam(self: RunContext, idx: usize) *i64 {
        return &self.code[@intCast(self.code[self.ip + idx + 1])];
    }

    pub fn run(self: *RunContext) !void {
        while (self.ip < self.code.len) {
            if (!try self.step()) break;
        }
    }
};

pub fn init(allocator: std.mem.Allocator, input: []const u8) !Self {
    var code: std.ArrayList(i64) = .empty;
    var it = std.mem.tokenizeScalar(u8, std.mem.trimEnd(u8, input, " \n"), ',');
    while (it.next()) |int| {
        try code.append(allocator, try std.fmt.parseInt(i64, int, 10));
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
