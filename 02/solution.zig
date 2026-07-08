const std = @import("std");

const Intcode = struct {
    code: []const u32,

    const Op = enum (u32) {
        add  = 1,
        mul  = 2,
        halt = 99,
    };

    const RunContext = struct {
        ip:     u32,
        code: []u32,

        fn init(allocator: std.mem.Allocator, code: []const u32) !RunContext {
            const copy = try allocator.dupe(u32, code);
            return .{ .ip = 0, .code = copy };
        }

        fn step(self: *RunContext) !bool {
            if (self.ip >= self.code.len) return error.NoHalt;

            const op: Op = @enumFromInt(self.code[self.ip]);
            switch (op) {
                .add => { // add,a,b,res
                    const a = self.code[self.code[self.ip + 1]];
                    const b = self.code[self.code[self.ip + 2]];
                    self.code[self.code[self.ip + 3]] = a + b;
                    self.ip += 4;
                },
                .mul => { // mul,a,b,res
                    const a = self.code[self.code[self.ip + 1]];
                    const b = self.code[self.code[self.ip + 2]];
                    self.code[self.code[self.ip + 3]] = a * b;
                    self.ip += 4;
                },
                .halt => {
                    self.ip += 1;
                    return false;
                }
            }
            return true;
        }

        fn run(self: *RunContext) !void {
            while (self.ip < self.code.len) {
                if (!try self.step()) break;
            }
        }
    };

    pub fn init(allocator: std.mem.Allocator, input: []const u8) !Intcode {
        var code: std.ArrayList(u32) = .empty;
        var it = std.mem.tokenizeScalar(u8, std.mem.trimEnd(u8, input, " \n"), ',');
        while (it.next()) |int| {
            try code.append(allocator, try std.fmt.parseUnsigned(u8, int, 10));
        }
        return .{ .code = code.items };
    }

    fn run(self: *Intcode, allocator: std.mem.Allocator) !RunContext {
        var ctx = try self.newContext(allocator);
        try ctx.run();
        return ctx;
    }

    fn newContext(self: Intcode, allocator: std.mem.Allocator) !RunContext {
        return try RunContext.init(allocator, self.code);
    }
};

pub fn main(init: std.process.Init) !void {
    const input = @embedFile("input");

    var program = try Intcode.init(init.arena.allocator(), input);

    var p1 = try program.newContext(init.arena.allocator());
    p1.code[1] = 12;
    p1.code[2] =  2;
    try p1.run();

    var p2: Intcode.RunContext = undefined;
    const p2_res = res: while (true) {
        for (0..100) |noun| for (0..100) |verb| {
            p2 = try program.newContext(init.arena.allocator());
            p2.code[1] = @intCast(noun);
            p2.code[2] = @intCast(verb);
            try p2.run();

            if (p2.code[0] == 19690720) break :res 100 * noun + verb;
        };
    };

    std.debug.print("Part 1: {}\n", .{ p1.code[0] });
    std.debug.print("Part 2: {}\n", .{ p2_res });
}

test "examples" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var program = try Intcode.init(arena.allocator(), "1,1,1,4,99,5,6,0,99");
    const   res = try program.run(arena.allocator());

    try std.testing.expectEqual(30, res.code[0]);
}
