const std = @import("std");

const Intcode = @import("intcode.zig");

pub fn main(init: std.process.Init) !void {
    const input = @embedFile("input");
    const alloc = init.arena.allocator();

    var buf: std.ArrayList(Intcode.Word) = .empty;
    try buf.append(alloc, 1);

    var program = try Intcode.init(alloc, input);
    _ = try program.run(alloc, .{ .buf = &buf }, .{ .buf = &buf, .allocator = alloc });
    std.debug.print("Part 1: {}\n", .{ buf.items[1] });

    buf.clearRetainingCapacity();
    try buf.append(alloc, 2);
    _ = try program.run(alloc, .{ .buf = &buf }, .{ .buf = &buf, .allocator = alloc });
    std.debug.print("Part 2: {}\n", .{ buf.items[1] });
}

test "examples" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();
    var buf: std.ArrayList(Intcode.Word) = .empty;

    var p1 = try Intcode.init(alloc, "109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99");
    _ = try p1.run(alloc, null, .{ .buf = &buf, .allocator = alloc });
    try std.testing.expectEqualSlices(Intcode.Word, p1.code, buf.items);

    buf.clearRetainingCapacity();
    var p2 = try Intcode.init(alloc, "1102,34915192,34915192,7,4,7,99,0");
    _ = try p2.run(alloc, null, .{ .buf = &buf, .allocator = alloc });
    try std.testing.expect(buf.items[0] > 1_000_000_000_000_000);

    buf.clearRetainingCapacity();
    var p3 = try Intcode.init(alloc, "104,1125899906842624,99");
    _ = try p3.run(alloc, null, .{ .buf = &buf, .allocator = alloc });
    try std.testing.expectEqual(1125899906842624, buf.items[0]);
}
