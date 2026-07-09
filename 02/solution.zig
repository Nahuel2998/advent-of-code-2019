const std = @import("std");

const Intcode = @import("intcode.zig");

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
