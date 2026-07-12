const std = @import("std");

const IMAGE_HEIGHT = 6;
const IMAGE_WIDTH  = 25;
const IMAGE_SIZE   = IMAGE_WIDTH * IMAGE_HEIGHT;

// I later learned this is WindowIterator but keeping this here
const SliceIterator = struct {
    buf: []const u8,
    idx:   usize = 0,
    size:  usize,

    pub fn next(self: *SliceIterator) ?[]const u8 {
        if (self.idx >= self.buf.len) return null;
        const start = self.idx;
        self.idx   += self.size;
        return self.buf[start..self.idx];
    }
};

fn part1(input: []const u8) u32 {
    var res:   u32 = undefined;
    var min_z: u32 = std.math.maxInt(u32);

    var it = SliceIterator{ .buf = input, .size = IMAGE_SIZE };
    while (it.next()) |layer| {
        var zeros: u32 = 0;
        var ones:  u32 = 0;
        var twos:  u32 = 0;
        for (layer) |ch| switch (ch) {
            '0'  => zeros += 1,
            '1'  => ones  += 1,
            '2'  => twos  += 1,
            else => unreachable,
        };
        if (zeros < min_z) {
            min_z = zeros;
            res   = ones * twos;
        }
    }
    return res;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const res = try allocator.alloc(u8, 25 * 6); // Why is this const if we modify it after..?
    @memset(res, ' ');

    // We probably don't have to go through every layer but sure
    var it = SliceIterator{ .buf = input, .size = IMAGE_SIZE };
    while (it.next()) |layer| {
        for (layer, res) |ch, *rch| {
            if (rch.* != ' ' or ch == '2') continue;
            rch.* = switch (ch) {
                '0'  => '.',
                '1'  => '#',
                else => unreachable,
            };
        }
    }
    return res;
}

pub fn main(init: std.process.Init) !void {
    const input = std.mem.trimEnd(u8, @embedFile("input"), "\n");
    std.debug.print("Part 1: {}\n", .{ part1(input) });

    std.debug.print("Part 2:\n", .{});
    const image = try part2(init.arena.allocator(), input);
    var it = SliceIterator{ .buf = image, .size = IMAGE_WIDTH };
    while (it.next()) |row| {
        std.debug.print("{s}\n", .{row});
    }
}
