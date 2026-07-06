const std = @import("std");

fn fuelRequirement(mass: u32) u32 {
    return mass / 3 -| 2;
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]u32 {
    var res = std.ArrayList(u32).empty;
    var it  = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        try res.append(allocator, try std.fmt.parseUnsigned(u32, line, 10));
    }
    return res.items;
}

fn part1(masses: []u32) u32 {
    var res: u32 = 0;
    for (masses) |mass| {
        res += fuelRequirement(mass);
    }
    return res;
}

// I don't think a cache is needed here,
// we don't even reach the u32 limit
fn part2(masses: []u32) u32 {
    var res: u32 = 0;
    for (masses) |mass| {
        var curr = fuelRequirement(mass);
        while (curr != 0) {
            res += curr;
            curr = fuelRequirement(curr);
        }
    }
    return res;
}

pub fn main(init: std.process.Init) !void {
    const input  = @embedFile("input");
    const masses = try parseInput(init.arena.allocator(), input);
    std.debug.print("Part 1: {}\n", .{ part1(masses) });
    std.debug.print("Part 2: {}\n", .{ part2(masses) });
}

test "examples" {
    try std.testing.expectEqual(2,     fuelRequirement(12));
    try std.testing.expectEqual(2,     fuelRequirement(14));
    try std.testing.expectEqual(654,   fuelRequirement(1969));
    try std.testing.expectEqual(33583, fuelRequirement(100756));
}
