// Let's never turn our input into actual numbers
const std = @import("std");

fn exceedsMax(buf: []const u8, max: []const u8) bool {
    for (0..buf.len) |i| {
        if (buf[i] == max[i]) continue;
        return buf[i] > max[i];
    }
    return false;
}

fn repeatsContiguous(buf: []const u8) bool {
    for (1..buf.len) |i| {
        if (buf[i - 1] == buf[i]) return true;
    }
    return false;
}

fn hasPair(buf: []const u8) bool {
    var i: usize = 0;
    while (i < buf.len - 1) {
        var count: usize = 0;
        for (buf[i..]) |ch| {
            if (buf[i] != ch) break;
            count += 1;
        }
        if (count == 2) return true;
        i += count;
    }
    return false;
}

fn countMatching(comptime checkFn: fn([]const u8)bool, min: []const u8, max: []const u8) u32 {
    var buf: [6]u8 = min[0..6].*;

    // First valid
    for (1..buf.len) |i| {
        if (buf[i - 1] > buf[i]) {
            buf[i] = buf[i - 1];
        }
    }

    var res: u32 = 0;
    while (!exceedsMax(&buf, max)) {
        if (checkFn(&buf)) res += 1;

        for (0..buf.len) |rev_i| {
            const i = buf.len - (rev_i + 1);
            if (buf[i] == '9') continue;

            const ch = buf[i] + 1;
            for (buf[i..]) |*bch| {
                bch.* = ch;
            }
            break;
        }
    }
    return res;
}

pub fn main(init: std.process.Init) void {
    _ = init;
    const input = @embedFile("input");

    const min = input[0..6];
    const max = input[7..13];

    const p1 = countMatching(repeatsContiguous, min, max);
    std.debug.print("Part 1: {}\n", .{ p1 });

    const p2 = countMatching(hasPair, min, max);
    std.debug.print("Part 2: {}\n", .{ p2 });
}

test "examples" {
    try std.testing.expectEqual(1, countMatching(repeatsContiguous, "111111", "111111"));
    try std.testing.expectEqual(0, countMatching(repeatsContiguous, "223450", "223450"));
    try std.testing.expectEqual(0, countMatching(repeatsContiguous, "123789", "123789"));

    try std.testing.expectEqual(1, countMatching(hasPair, "112233", "112233"));
    try std.testing.expectEqual(0, countMatching(hasPair, "123444", "123444"));
    try std.testing.expectEqual(1, countMatching(hasPair, "111122", "111122"));
}
