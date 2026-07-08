const std = @import("std");

const Wire = struct {
    horizontal: []Line,
    vertical:   []Line,

    pub fn init(allocator: std.mem.Allocator, input: []const u8) !Wire {
        var horizontal: std.ArrayList(Line) = .empty;
        var vertical:   std.ArrayList(Line) = .empty;

        var it = std.mem.splitScalar(u8, input, ',');
        var steps:  u32 = 0;
        var pos: [2]i32 = .{ 0, 0 }; // .{ x, y }
        while (it.next()) |cmd| {
            const len = try std.fmt.parseUnsigned(i32, cmd[1..], 10);
            switch (cmd[0]) {
                'R' => {
                    const line: Line = .{
                        .pos   = pos[1],
                        .start = pos[0],
                        .end   = pos[0] + len,
                        .steps = steps,
                    };
                    pos[0] += len;
                    try horizontal.append(allocator, line);
                },
                'L' => {
                    const line: Line = .{
                        .pos   = pos[1],
                        .start = pos[0],
                        .end   = pos[0] - len,
                        .steps = steps,
                    };
                    pos[0] -= len;
                    try horizontal.append(allocator, line);
                },
                'U' => {
                    const line: Line = .{
                        .pos   = pos[0],
                        .start = pos[1],
                        .end   = pos[1] + len,
                        .steps = steps,
                    };
                    pos[1] += len;
                    try vertical.append(allocator, line);
                },
                'D' => {
                    const line: Line = .{
                        .pos   = pos[0],
                        .start = pos[1],
                        .end   = pos[1] - len,
                        .steps = steps,
                    };
                    pos[1] -= len;
                    try vertical.append(allocator, line);
                },
                else => unreachable,
            }
            steps += @intCast(len);
        }
        return .{
            .horizontal = horizontal.items,
            .vertical   =   vertical.items,
        };
    }
};
const Line = struct {
    pos:   i32,
    start: i32, 
    end:   i32,
    steps: u32,

    pub fn intersects(self: Line, other: Line) bool {
        const a = @min(self.start, self.end);
        const b = @max(self.start, self.end);
        if (a > other.pos or other.pos > b) return false;

        const oa = @min(other.start, other.end);
        const ob = @max(other.start, other.end);
        return oa <= self.pos and self.pos <= ob;
    }
};

fn manhattanLen(h: Line, v: Line) u32 {
    return @abs(h.pos) + @abs(v.pos);
}
fn stepsLen(h: Line, v: Line) u32 {
    return ( h.steps + @abs(v.pos - h.start) ) + ( v.steps + @abs(h.pos - v.start) );
}
fn closest(comptime lenFn: fn(Line, Line)u32, wires: [2]Wire) u32 {
    var res: u32 = std.math.maxInt(u32);
    for (0..2) |i| {
        for (wires[i].horizontal) |h| for (wires[(i + 1) % 2].vertical) |v| {
            if (h.intersects(v)) {
                const newres: u32 = lenFn(h, v);
                if (newres == 0) continue;
                if (newres < res) {
                    res = newres;
                }
            }
        };
    }
    return res;
}

pub fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![2]Wire {
    var res: [2]Wire = undefined;

    var i: usize = 0;
    var it = std.mem.tokenizeAny(u8, input, " \n");
    while (it.next()) |wire| : (i += 1) {
        res[i] = try .init(allocator, wire);
    }
    std.debug.assert(i == 2);

    return res;
}

pub fn main(init: std.process.Init) !void {
    const input = @embedFile("input");
    const wires = try parseInput(init.arena.allocator(), input);

    std.debug.print("Part 1: {}\n", .{ closest( manhattanLen, wires ) });
    std.debug.print("Part 2: {}\n", .{ closest( stepsLen    , wires ) });
}

test "example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input =
        \\ R75,D30,R83,U83,L12,D49,R71,U7,L72
        \\ U62,R66,U55,R34,D71,R55,D58,R83
    ;
    const wires = try parseInput(arena.allocator(), input);

    const closestM = closest(manhattanLen, wires);
    try std.testing.expectEqual(159, closestM);

    const closestS = closest(stepsLen, wires);
    try std.testing.expectEqual(610, closestS);
}
