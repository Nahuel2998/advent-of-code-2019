const std = @import("std");

const Intcode = @import("intcode.zig");

pub fn main(init: std.process.Init) !void {
    const input = @embedFile("input");
    const alloc = init.arena.allocator();

    const program = try Intcode.init(alloc, input);

    var out: std.ArrayList(i32) = .empty;
    _ = try program.run(alloc, .{ .buf = &.{1} }, .{ .buf = &out, .allocator = alloc });
    std.debug.print("Part 1: {}\n", .{ out.getLast() });

    out.clearRetainingCapacity();
    _ = try program.run(alloc, .{ .buf = &.{5} }, .{ .buf = &out, .allocator = alloc });
    std.debug.print("Part 2: {}\n", .{ out.getLast() });
}

test "examples" {
    var   arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    const t1 = try (try Intcode.init(alloc, "1002,4,3,4,33")).run(alloc, null, null);
    try std.testing.expectEqual(99, t1.code[4]);

    var   out: std.ArrayList(i32) = .empty;
    const program = try Intcode.init(alloc, "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99");

    _ = try program.run(alloc, .{ .buf = &.{7} }, .{ .buf = &out, .allocator = alloc });
    try std.testing.expectEqual(999,  out.items[0]);

    _ = try program.run(alloc, .{ .buf = &.{8} }, .{ .buf = &out, .allocator = alloc });
    try std.testing.expectEqual(1000, out.items[1]);

    _ = try program.run(alloc, .{ .buf = &.{9} }, .{ .buf = &out, .allocator = alloc });
    try std.testing.expectEqual(1001, out.items[2]);
}
