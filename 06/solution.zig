const std = @import("std");

const ObjectId = [3]u8;
const Object   = struct {
    orbiting: ?ObjectId = null,
    orbiters: std.ArrayList(ObjectId) = .empty,

    pub fn countOrbits(self: Object, objects: Objects, level: u32) u32 {
        var res: u32 = 0;
        for (self.orbiters.items) |id| {
            const obj = objects.get(id).?;
            res += obj.countOrbits(objects, level + 1);
        }
        return res + level;
    }

    pub fn findOrbiting(self: Object, allocator: std.mem.Allocator, objects: Objects) ![]ObjectId {
        var res: std.ArrayList(ObjectId) = .empty;
        var curr = self;
        while (curr.orbiting) |obj| : (curr = objects.get(obj).?) {
            try res.append(allocator, obj);
        }
        return res.items;
    }
};
const Objects = std.AutoHashMapUnmanaged(ObjectId, Object);

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !Objects {
    var res: Objects = .empty;
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |orb| {
        const paren_id: ObjectId = orb[0..3].*;
        const child_id: ObjectId = orb[4..7].*;

        const paren = try res.getOrPut(allocator, paren_id);
        if (!paren.found_existing) paren.value_ptr.* = .{};
        try paren.value_ptr.orbiters.append(allocator, child_id);

        const child = try res.getOrPut(allocator, child_id);
        if (!child.found_existing) child.value_ptr.* = .{};
        child.value_ptr.orbiting = paren_id;
    }
    return res;
}

fn part1(objects: Objects) u32 {
    const com = objects.get("COM".*).?;
    return com.countOrbits(objects, 0);
}

fn part2(allocator: std.mem.Allocator, objects: Objects) !usize {
    const you = try objects.get("YOU".*).?.findOrbiting(allocator, objects);
    const san = try objects.get("SAN".*).?.findOrbiting(allocator, objects);

    var i: usize = 1;
    while (true) : (i += 1) {
        if (!std.meta.eql(you[you.len - i], san[san.len - i])) {
            return (you.len - i) + (san.len - i) + 2;
        }
    }
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    const input = @embedFile("input");

    const objects = try parseInput(allocator, input);
    std.debug.print("Part 1: {}\n", .{ part1(objects) });
    std.debug.print("Part 2: {}\n", .{ try part2(init.arena.allocator(), objects) });
}

test "example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = @embedFile("example");

    const objects = try parseInput(arena.allocator(), input);
    try std.testing.expectEqual(54,     part1(                   objects));
    try std.testing.expectEqual(4,  try part2(arena.allocator(), objects));
}
