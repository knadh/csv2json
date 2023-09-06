const std = @import("std");
const clap = @import("clap");
const csv = @import("csv");
const Converter = @import("./converter.zig").Converter;

// Print flag usage to stdout.
pub fn printHelp(comptime params: []const clap.Param(clap.Help)) !void {
    std.debug.print("Convert CSV to JSON files.\n", .{});
    try clap.help(
        std.io.getStdErr().writer(),
        clap.Help,
        params,
        .{},
    );
}

pub fn printStats(start: u64, end: u64, lines: u64) void {
    const diff = @as(f64, @floatFromInt(end - start));
    const ln = @as(f64, @floatFromInt(lines));

    var val: f64 = 0;
    var unit: []const u8 = undefined;

    if (diff < std.time.ns_per_us) {
        val = diff;
        unit = "nanoseconds";
    } else if (diff < std.time.ns_per_ms) {
        val = diff / @as(f64, @floatFromInt(std.time.ns_per_us));
        unit = "microseconds";
    } else if (diff < std.time.ns_per_s) {
        val = diff / @as(f64, @floatFromInt(std.time.ns_per_ms));
        unit = "milliseconds";
    } else {
        val = diff / @as(f64, @floatFromInt(std.time.ns_per_s));
        unit = "seconds";
    }

    var rate = ln / (diff / @as(f64, @floatFromInt(std.time.ns_per_s)));
    if (rate > ln) {
        rate = ln;
    }

    std.debug.print("Processed {d} lines in {d:.2} {s} ({d:.2} lines / second)\n", .{ lines, val, unit, rate });
}

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\ -h, --help
        \\         Display this help and exit.
        \\ -i, --in <STR>
        \\         Path to input CSV file.
        \\ -b, --buf <INT>
        \\         Line buffer (default: 4096). Should be greater than the longest line.
    );

    const parsers = comptime .{
        .STR = clap.parsers.string,
        .INT = clap.parsers.int(u32, 0),
    };

    // Help / usage.
    var args = clap.parse(clap.Help, &params, parsers, .{}) catch |err| {
        std.debug.print("Invalid flags: {s}\n\n", .{@errorName(err)});
        try printHelp(&params);
        std.os.exit(1);
    };
    defer args.deinit();

    if (args.args.help != 0) {
        try printHelp(&params);
        std.os.exit(1);
    }

    var bufSize: u32 = 4096;
    if (args.args.buf) |b|
        std.debug.print("Buffer size: {d}\n", .{b});

    if (args.args.in) |fPath| {
        std.debug.print("Reading {s} ...\n", .{fPath});

        var timer = try std.time.Timer.start();
        const start = timer.read();

        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();

        var allocator = arena.allocator();

        var conv = try Converter.init(allocator, std.io.getStdOut().writer(), bufSize);

        const lines = try conv.convert(fPath);

        printStats(start, timer.read(), lines);
        std.os.exit(0);
    }

    // No flags.
    try printHelp(&params);
}
