const std = @import("std");

const Asteroids = std.AutoHashMapUnmanaged(Position, []Position);
const Position  = struct {
    x: i32,
    y: i32,

    fn sub(self: Position, other: Position) Position {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    fn reduce(self: Position) Position {
        const gcd: i32 = @intCast(std.math.gcd(@abs(self.x), @abs(self.y)));
        return .{
            .x = @divExact(self.x, gcd),
            .y = @divExact(self.y, gcd),
        };
    }

    fn pseudoangle(self: Position) f32 {
        const x: f32 = @floatFromInt(self.x);
        const y: f32 = @floatFromInt(self.y);
        const r: f32 = x / ( @abs(x) + @abs(y) );
        if (y < 0) {
            if (x < 0) {
                return 4 + r;
            }
            return r;
        }
        return 2 - r;
    }

    fn angleLessThan(_: void, lhs: Position, rhs: Position) bool {
        return lhs.pseudoangle() < rhs.pseudoangle();
    }

    fn distanceLessThan(_: void, lhs: Position, rhs: Position) bool {
        return (lhs.x * lhs.x + lhs.y * lhs.y) < (rhs.x * rhs.x + rhs.y * rhs.y);
    }
};

fn deinitAsteroids(allocator: std.mem.Allocator, asteroids: *Asteroids) void {
    var it = asteroids.valueIterator();
    while (it.next()) |asts| {
        allocator.free(asts.*);
    }
    asteroids.deinit(allocator);
}

fn visibleAsteroids(allocator: std.mem.Allocator, asteroids: []Position, from: Position) !Asteroids {
    var lines: std.AutoHashMapUnmanaged(Position, std.ArrayList(Position)) = .empty;
    defer lines.deinit(allocator);

    for (asteroids) |other| {
        if (std.meta.eql(from, other)) continue;

        const key   = other.sub(from).reduce();
        const entry = try lines.getOrPut(allocator, key);
        if (!entry.found_existing) entry.value_ptr.* = .empty;
        try entry.value_ptr.append(allocator, other);
    }

    var res: Asteroids = .empty;
    var it = lines.iterator();
    while (it.next()) |entry| {
        const asts = try entry.value_ptr.toOwnedSlice(allocator);
        try res.put(allocator, entry.key_ptr.*, asts);
    }
    return res;
}

fn optimalPoint(allocator: std.mem.Allocator, asteroids: []Position) !Position {
    var lines: std.AutoHashMapUnmanaged(Position, void) = .empty;
    defer lines.deinit(allocator);

    var res: Position = undefined;
    var max: u32 = 0;
    for (asteroids) |ast| {
        lines.clearRetainingCapacity();
        for (asteroids) |other| {
            if (std.meta.eql(ast, other)) continue;

            try lines.put(allocator, other.sub(ast).reduce(), {});
        }

        const newmax = lines.count();
        if (newmax > max) {
            res = ast;
            max = newmax;
        }
    }
    return res;
}

fn part1(asteroids: Asteroids) u32 {
    return asteroids.count();
}

fn part2(allocator: std.mem.Allocator, asteroids: Asteroids) !i32 {
    var keys: std.ArrayList(Position) = .empty;
    defer keys.deinit(allocator);

    var it = asteroids.iterator();
    while (it.next()) |entry| {
        try keys.append(allocator, entry.key_ptr.*);
        std.sort.insertion(Position, entry.value_ptr.*, {}, Position.distanceLessThan);
    }
    std.sort.pdq(Position, keys.items, {}, Position.angleLessThan);

    var i:   usize = 0;
    var rot: usize = 0;
    while (true) : (rot += 1) for (keys.items) |key| {
        const asts = asteroids.get(key).?;
        if (asts.len <= rot) continue;

        i += 1;
        if (i == 200) {
            const ast = asts[rot];
            return ast.x * 100 + ast.y;
        }
    };
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]Position {
    var res: std.ArrayList(Position) = .empty;

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    var y: i32 = 0;
    while (it.next()) |line| : (y += 1) {
        for (line, 0..) |ch, x| if (ch == '#') {
            try res.append(allocator, .{ .x = @intCast(x), .y = y });
        };
    }

    return res.toOwnedSlice(allocator);
}

pub fn main(init: std.process.Init) !void {
    const input = @embedFile("input");

    const asts = try parseInput(init.arena.allocator(), input);

    const point = try optimalPoint(init.gpa, asts);
    var visible = try visibleAsteroids(init.gpa, asts, point);
    defer deinitAsteroids(init.gpa, &visible);

    std.debug.print("Part 1: {}\n", .{ part1(visible) });
    std.debug.print("Part 2: {}\n", .{ try part2(init.gpa, visible) });
}

test "examples" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const input = 
        \\.#..##.###...#######
        \\##.############..##.
        \\.#.######.########.#
        \\.###.#######.####.#.
        \\#####.##.#.##.###.##
        \\..#####..#.#########
        \\####################
        \\#.####....###.#.#.##
        \\##.#################
        \\#####.##.###..####..
        \\..######..##.#######
        \\####.##.####...##..#
        \\.#####..#.######.###
        \\##...#.##########...
        \\#.##########.#######
        \\.####.#.###.###.#.##
        \\....##.##.###..#####
        \\.#.#.###########.###
        \\#.#.#.#####.####.###
        \\###.##.####.##.#..##
    ;
    const asts  = try parseInput(alloc, input);
    const point = try optimalPoint(std.testing.allocator, asts);
    var visible = try visibleAsteroids(std.testing.allocator, asts, point);
    defer deinitAsteroids(std.testing.allocator, &visible);

    try std.testing.expectEqual(210, part1(visible));
    try std.testing.expectEqual(802, try part2(std.testing.allocator, visible));
}

test "pseudoangle" {
    const up = Position{ .x = 0, .y = -1 };
    try std.testing.expectEqual(0, up.pseudoangle());

    const right = Position{ .x = 1, .y = 0 };
    try std.testing.expectEqual(1, right.pseudoangle());

    const down = Position{ .x = 0, .y = 1 };
    try std.testing.expectEqual(2, down.pseudoangle());

    const left = Position{ .x = -1, .y = 0 };
    try std.testing.expectEqual(3, left.pseudoangle());

    const leup = Position{ .x = -1, .y = -1 };
    try std.testing.expectEqual(3.5, leup.pseudoangle());
}
