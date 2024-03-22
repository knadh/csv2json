const std = @import("std");
const csv = @import("csv");

pub const Converter = struct {
    const BufferedWriter = std.io.BufferedWriter(4096, std.fs.File.Writer);

    allocator: std.mem.Allocator,
    csvBuf: []u8,
    hdrBuf: []u8,
    rowBuf: []u8,
    keys: [][]const u8,
    out: BufferedWriter,

    const Self = @This();

    // Initialize the converter.
    pub fn init(allocator: std.mem.Allocator, writer: anytype, rowBufSize: u32) !Self {
        const s = Converter{
            .allocator = allocator,
            .out = std.io.bufferedWriter(writer),
            .csvBuf = try allocator.alloc(u8, rowBufSize),
            .hdrBuf = try allocator.alloc(u8, rowBufSize),
            .rowBuf = try allocator.alloc(u8, rowBufSize),
            .keys = undefined,
        };

        return s;
    }

    pub fn deinit(self: *Self) void {
        if (self.csvBuf) self.allocator.free(self.csvBuf);
        if (self.hdrBuf) self.allocator.free(self.hdrBuf);
        if (self.rowBuf) self.allocator.free(self.rowBuf);
    }

    // Convert a CSV file. rowBufSize should be greater than the length (bytes)
    // of the biggest row in the CSV file.
    pub fn convert(self: *Self, filePath: []const u8) !u64 {
        const file = try std.fs.cwd().openFile(filePath, .{});
        defer file.close();
        var tk = try csv.CsvTokenizer(std.fs.File.Reader).init(file.reader(), self.csvBuf, .{});

        var fields = std.ArrayList([]const u8).init(std.heap.page_allocator);
        var isFirst: bool = true;
        var line: u64 = 1;
        var f: usize = 0;

        while (try tk.next()) |token| {
            switch (token) {
                .field => |val| {
                    // Copy the incoming field slice to the row buffer.
                    const ln: usize = f + val.len;

                    if (isFirst) {
                        // Copy all the fields in the first row to a separate buffer
                        // to be retained throughout the lifetime of the program.
                        std.mem.copyForwards(u8, self.hdrBuf[f..ln], val);
                        try fields.append(self.hdrBuf[f..ln]);
                    } else {
                        // Row buffer can be discarded after processing each individual row.
                        std.mem.copyForwards(u8, self.rowBuf[f..ln], val);
                        try fields.append(self.rowBuf[f..ln]);
                    }

                    f = ln;
                },
                .row_end => {
                    f = 0;

                    // Move the first row (header) fields to be reused with every subsequent
                    // row as JSON keys.
                    if (isFirst) {
                        isFirst = false;
                        self.keys = try fields.toOwnedSlice();
                        continue;
                    }

                    try self.writeJSON(fields, line);
                    try fields.resize(0);

                    line += 1;
                },
            }
        }

        try self.out.flush();

        return line;
    }

    // Writes a list of "value" fields from a row as a JSON dict.
    fn writeJSON(self: *Self, vals: std.ArrayList([]const u8), line: u64) !void {
        if (self.keys.len != vals.items.len) {
            std.debug.print("Invalid field count on line {d}: {d} (headers) != {d} (fields).\n", .{ line, self.keys.len, vals.items.len });
            return;
        }

        try self.out.writer().writeAll("{");

        for (self.keys, 0..) |key, n| {
            // Write the key.
            try self.out.writer().writeAll("\"");
            try self.out.writer().writeAll(key);
            try self.out.writer().writeAll("\": ");

            // Write the value.
            if (vals.items[n].len == 0) {
                try self.out.writer().writeAll("null");
            } else {
                try self.writeValue(vals.items[n], true);
            }

            // If it's not the last key, write a comma.
            if (n < self.keys.len - 1) {
                try self.out.writer().writeAll(", ");
            }
        }

        try self.out.writer().writeAll("}\n");
    }

    fn writeValue(self: *Self, val: []const u8, detectNum: bool) !void {
        // If the first char is a digit, then try and iterate through the rest
        // of the chars to see if it's a number.
        if (detectNum and std.ascii.isDigit(val[0])) {
            var hasPeriod: bool = false;
            var isNum: bool = true;
            for (val) |c| {
                // Already found a period.
                if (hasPeriod) {
                    isNum = false;
                    break;
                }
                if (c == '.') {
                    hasPeriod = true;
                }
                if (!std.ascii.isDigit(c)) {
                    isNum = false;
                    break;
                }
            }

            if (isNum) {
                try self.out.writer().writeAll(val);
                return;
            }
        }

        // It's a string.
        try self.out.writer().writeAll("\"");

        // Iterate through the string to see if there are any quotes to escape.
        // If there aren't, doing a writeAll() is faster than than doing a .write() per character.
        if (hasQuote(val)) {
            for (val) |c| {
                // Escape quotes.
                if (c == '"') {
                    _ = try self.out.writer().write("\\");
                }
                _ = try self.out.writer().write(&[_]u8{c});
            }
        } else {
            try self.out.writer().writeAll(val);
        }
        try self.out.writer().writeAll("\"");
    }

    fn hasQuote(val: []const u8) bool {
        for (val) |c| {
            if (c == '"') {
                return true;
            }
        }
        return false;
    }
};
