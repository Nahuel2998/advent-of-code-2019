const std = @import("std");
const Intcode = @import("intcode.zig");

const PHASES_1 = &[_]i32{0, 1, 2, 3, 4};
const PHASES_2 = &[_]i32{5, 6, 7, 8, 9};

// FIXME: Make this not do that many allocs?
fn permutations(allocator: std.mem.Allocator, items: []const i32) ![][]i32 {
    var res: std.ArrayList([]i32) = .empty;
    if (items.len == 1) {
        const buf = try allocator.dupe(i32, items);
        try res.append(allocator, buf);
        return try res.toOwnedSlice(allocator);
    }

    var others_buf: []i32 = try allocator.alloc(i32, items.len - 1);
    defer allocator.free(others_buf);

    for (items) |lead| {
        var i: usize = 0;
        for (items) |other| {
            if (lead == other) continue;
            others_buf[i] = other;
            i += 1;
        }

        const perms = try permutations(allocator, others_buf);
        defer allocator.free(perms);

        for (perms) |perm| {
            defer allocator.free(perm);

            var buf: []i32 = try allocator.alloc(i32, items.len);
            buf[0] = lead;
            @memcpy(buf[1..], perm);

            try res.append(allocator, buf);
        }
    }
    return try res.toOwnedSlice(allocator);
}

fn maxThrusterSignal(allocator: std.mem.Allocator, program: Intcode, perms: [][]i32) !i32 {
    var res: i32 = 0;

    var bufs: [5]std.ArrayList(i32) = .{ std.ArrayList(i32).empty } ** 5;
    var runs: [5]Intcode.RunContext = undefined;
    for (perms) |perm| {
        for (&bufs, perm, &runs, 0..) |*buf, phase, *run, i| {
            buf.clearRetainingCapacity();
            try buf.append(allocator, phase);

            run.* = try program.newContext(allocator);
            run.stdin  = .{ .buf = &bufs[i] };
            run.stdout = .{ .buf = &bufs[(i + 1) % bufs.len], .allocator = allocator };
        }
        try bufs[0].append(allocator, 0);

        var cont = true;
        while (cont) for (&runs) |*run| {
            cont = false;
            run.run() catch |err| switch (err) {
                error.AwaitingInput => cont = true,
                else                => unreachable,
            };
        };

        const newres = bufs[0].getLast();
        if (newres > res) res = newres;
    }
    return res;
}

pub fn main(init: std.process.Init) !void {
    const input = @embedFile("input");
    const alloc = init.arena.allocator();

    const program = try Intcode.init(alloc, input);
    const perms1  = try permutations(alloc, PHASES_1);
    const perms2  = try permutations(alloc, PHASES_2);

    const p1 = try maxThrusterSignal(alloc, program, perms1);
    std.debug.print("Part 1: {}\n", .{p1});

    const p2 = try maxThrusterSignal(alloc, program, perms2);
    std.debug.print("Part 2: {}\n", .{p2});
}

test "examples" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const program1 = try Intcode.init(allocator, "3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0");
    const perms1   = try permutations(allocator, PHASES_1);
    const res1     = try maxThrusterSignal(allocator, program1, perms1);
    try std.testing.expectEqual(43210, res1);

    const program2 = try Intcode.init(allocator, "3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5");
    const perms2   = try permutations(allocator, PHASES_2);
    const res2     = try maxThrusterSignal(allocator, program2, perms2);
    try std.testing.expectEqual(139629729, res2);
}

test "permleaks" {
    const alloc = std.testing.allocator;

    const perms = try permutations(alloc, PHASES_1);
    defer alloc.free(perms);

    for (perms) |perm| {
        alloc.free(perm);
    }
}
