const std = @import("std");
const clap = @import("clap");
const csv = @import("csv");
const Converter = @import("./converter.zig").Converter;

// Print flag usage to stdout.
pub fn printHelp(comptime params: []const clap.Param(clap.Help)) !void {
    std.debug.print("Convert CSV to JSON files.\n", .{});
    try clap.help(
        std.io.getStdErr().writer(),
        params,
    );
}

pub fn printStats(start: u64, end: u64, lines: u64) void {
    const diff = @intToFloat(f64, end - start);
    const ln = @intToFloat(f64, lines);

    var val: f64 = 0;
    var unit: []const u8 = undefined;

    if (diff < std.time.ns_per_us) {
        val = diff;
        unit = "nano";
    } else if (diff < std.time.ns_per_ms) {
        val = diff / @intToFloat(f64, std.time.ns_per_us);
        unit = "micro";
    } else if (diff < std.time.ns_per_s) {
        val = diff / @intToFloat(f64, std.time.ns_per_ms);
        unit = "milli";
    } else {
        val = diff / @intToFloat(f64, std.time.ns_per_s);
    }

    var rate = ln / (diff / @intToFloat(f64, std.time.ns_per_s));
    if (rate > ln) {
        rate = ln;
    }

    std.debug.print("Processed {d} lines in {d:.2} {s}seconds ({d:.2} lines / second)\n", .{ lines, val, unit, rate });
}

pub fn main() !void {
    const params = comptime [_]clap.Param(clap.Help){
        clap.parseParam("-h, --help   Display this help and exit.") catch unreachable,
        clap.parseParam("-i, --in <STR>   Path to input CSV file.") catch unreachable,
        clap.parseParam("-a, --array <BOOL>   Convert rows to arrays instead of JSON lines.") catch unreachable,
        clap.parseParam("-b, --buf <UINT32>   Line buffer (default: 4096). Should be greater than the longest line.") catch unreachable,
    };

    // Help / usage.
    var args = clap.parse(clap.Help, &params, .{}) catch |err| {
        std.debug.print("invalid flags: {s}\n\n", .{@errorName(err)});
        try printHelp(&params);
        std.os.exit(1);
    };
    defer args.deinit();

    if (args.flag("--help")) {
        try printHelp(&params);
        std.os.exit(1);
    }

    var bufSize: u32 = 4096;
    if (args.option("--buf")) |b| {
        bufSize = std.fmt.parseUnsigned(u32, b, 10) catch |err| {
            std.debug.print("Invalid buffer size {s}\n\n", .{@errorName(err)}); // to fix the error: unused capture
            std.os.exit(1);
        };
    }

    if (args.option("--in")) |fPath| {
        std.debug.print("Reading {s} ...\n", .{fPath});

        var timer = try std.time.Timer.start();
        const start = timer.read();

        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        // New Error:
        // ./src/main.zig:79:45: error: expected type '*std.mem.Allocator', found '*const (bound fn(*std.heap.arena_allocator.ArenaAllocator) std.mem.Allocator)'
        //         var conv = try Converter.init(&arena.allocator, std.io.getStdOut().writer(), bufSize);
        //                                             ^
        // ./src/main.zig:79:45: note: cast discards const qualifier
        //         var conv = try Converter.init(&arena.allocator, std.io.getStdOut().writer(), bufSize);
        //                                             ^
        // /usr/lib/zig/std/start.zig:553:40: note: referenced here
        //             const result = root.main() catch |err| {
        //                                        ^
        // csv2json...The following command exited with error code 1:
        var conv = try Converter.init(&arena.allocator, std.io.getStdOut().writer(), bufSize);
        const lines = try conv.convert(fPath);

        printStats(start, timer.read(), lines);
        std.os.exit(0);
    }

    // No flags.
    try printHelp(&params);
}
