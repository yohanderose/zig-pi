const std = @import("std");
const utils = @import("utils.zig");
const BMP180Error = @import("errors.zig").BMP180Error;
const DeviceTypes = utils.DeviceTypes;
const UVec3 = utils.UVec3;
const Vec3 = utils.Vec3;

const DEVICE_ADDRESS = 0x77; // Identifier for BMP180

// Operating Modes
const ULTRALOWPOWER = 0;
const STANDARD = 1;
const HIGHRES = 2;
const ULTRAHIGHRES = 3;
const OSS = STANDARD;

// BMP185 Registers
const CAL_AC1 = 0xAA; //Calibration data (16 bits)
const CAL_AC2 = 0xAC; //Calibration data (16 bits)
const CAL_AC3 = 0xAE; //Calibration data (16 bits)
const CAL_AC4 = 0xB0; //Calibration data (16 bits)
const CAL_AC5 = 0xB2; //Calibration data (16 bits)
const CAL_AC6 = 0xB4; //Calibration data (16 bits)
const CAL_B1 = 0xB6; //Calibration data (16 bits)
const CAL_B2 = 0xB8; //Calibration data (16 bits)
const CAL_MB = 0xBA; //Calibration data (16 bits)
const CAL_MC = 0xBC; //Calibration data (16 bits)
const CAL_MD = 0xBE; //Calibration data (16 bits)

const CONTROL = 0xF4;
const TEMPDATA = 0xF6;
const PRESSUREDATA = 0xF6;

// Commands
const READTEMPCMD = 0x2E;
const READPRESSURECMD = 0x34;

const SEALEVEL_PRESSURE: f32 = 101325.0;

pub const Bmp180 = struct {
    is_active: bool = false,
    setup: *const fn (c_uint) anyerror!u8,
    cleanup: *const fn (c_uint) void,
    write: *const fn (c_uint, c_uint, c_uint) anyerror!void,
    read: *const fn (c_uint, c_uint) anyerror!u8,
    file_descriptor: *c_uint,
    temperature: f32 = 0.0,
    pressure: f32 = 0,
    altitude: f32 = 0.0,
    ac1: i32 = 0,
    ac2: i32 = 0,
    ac3: i32 = 0,
    ac4: u16 = 0,
    ac5: u16 = 0,
    ac6: u16 = 0,
    b1: i32 = 0,
    b2: i32 = 0,
    mb: i32 = 0,
    mc: i32 = 0,
    md: i32 = 0,

    fn read16(self: *Bmp180, addr: c_uint) !u16 {
        // send 1 byte, then read and return 2 bytes
        try self.write(self.file_descriptor.*, addr, 0);
        const high_byte: u16 = @intCast(try self.read(self.file_descriptor.*, addr));
        const low_byte: u16 = @intCast(try self.read(self.file_descriptor.*, addr + 1));
        return (high_byte << 8) | low_byte;
    }

    pub fn _setup(self: *Bmp180) !void {
        self.file_descriptor.* = try self.setup(DEVICE_ADDRESS);

        // Load calibration values
        self.ac1 = @as(i16, try self.read16(CAL_AC1));
        self.ac2 = @as(i16, try self.read16(CAL_AC2));
        self.ac3 = @as(i16, try self.read16(CAL_AC3));
        self.ac4 = try self.read16(CAL_AC4);
        self.ac5 = try self.read16(CAL_AC5);
        self.ac6 = try self.read16(CAL_AC6);
        self.b1 = @as(i16, try self.read16(CAL_B1));
        self.b2 = @as(i16, try self.read16(CAL_B2));
        self.mb = @as(i16, try self.read16(CAL_MB));
        self.mc = @as(i16, try self.read16(CAL_MC));
        self.md = @as(i16, try self.read16(CAL_MD));

        std.debug.print("AC1: {d}\n", .{self.ac1});
        std.debug.print("AC2: {d}\n", .{self.ac2});
        std.debug.print("AC3: {d}\n", .{self.ac3});
        std.debug.print("AC4: {d}\n", .{self.ac4});
        std.debug.print("AC5: {d}\n", .{self.ac5});
        std.debug.print("AC6: {d}\n", .{self.ac6});
        std.debug.print("B1: {d}\n", .{self.b1});
        std.debug.print("B2: {d}\n", .{self.b2});
        std.debug.print("MB: {d}\n", .{self.mb});
        std.debug.print("MC: {d}\n", .{self.mc});
        std.debug.print("MD: {d}\n", .{self.md});

        self.is_active = true;
    }

    pub fn _cleanup(self: *Bmp180) void {
        self.cleanup(self.file_descriptor.*);
    }

    fn read_raw_temperature(self: *Bmp180) !u16 {
        try self.write(self.file_descriptor.*, CONTROL, READTEMPCMD);
        std.time.sleep(5_000);
        return self.read16(TEMPDATA);
    }

    fn compute_b5(self: *Bmp180, raw_temperature: i64) i64 {
        const x1 = ((raw_temperature - self.ac6) * self.ac5) >> 15;
        const x2 = (@divTrunc(self.mc << 11, (x1 + self.md)));
        return x1 + x2;
    }

    pub fn _read_temperature(self: *Bmp180) bool {
        const raw_temperature = self.read_raw_temperature() catch return false;
        const b5 = self.compute_b5(@as(i64, raw_temperature));
        self.temperature = @as(f32, @floatFromInt((b5 + 8) >> 4)) / 10.0;
        return true;
    }

    fn read_raw_pressure(self: *Bmp180) !u32 {
        try self.write(self.file_descriptor.*, CONTROL, READPRESSURECMD + (OSS << 6));
        std.time.sleep(switch (OSS) {
            ULTRALOWPOWER => 5_000,
            HIGHRES => 14_000,
            ULTRAHIGHRES => 26_000,
            else => 8_000,
        });
        var raw: u32 = @intCast(try self.read16(PRESSUREDATA));
        const next: u32 = @intCast(try self.read16(PRESSUREDATA + 2));
        raw <<= 8;
        raw |= next;
        raw >>= (8 - OSS);
        return raw;
    }

    fn read_pressure(self: *Bmp180) bool {
        const _raw_temperature = self.read_raw_temperature() catch return false;
        const _raw_pressure = self.read_raw_pressure() catch return false;
        const raw_temperature: i64 = @as(i64, _raw_temperature);
        const raw_pressure: i64 = @as(i64, _raw_pressure);

        std.debug.print("Raw pressure {}\n", .{_raw_pressure});

        // Temperature compensation
        const b5: i64 = self.compute_b5(raw_temperature);

        // Pressure calculation
        const b6: i64 = b5 - 4000;
        var x1 = (self.b2 * ((b6 * b6) >> 12)) >> 11;
        var x2 = (self.ac2 * b6) >> 11;
        var x3: i64 = x1 + x2;
        const b3: i64 =
            @divTrunc((((self.ac1 * 4 + x3) << OSS) + 2), 4);

        x1 = (self.ac3 * b6) >> 13;
        x2 = (self.b1 * ((b6 * b6) >> 12)) >> 16;
        x3 = ((x1 + x2) + 2) >> 2;
        const b4: i64 = (self.ac4 * (x3 + 32768)) >> 15;
        const b7: i64 = (raw_pressure - b3) * (50000 >> OSS);

        var p: i64 = 0;
        if (b7 < 0x80000000) {
            p = @divTrunc(b7 * 2, b4);
        } else {
            p = @divTrunc(b7, b4) * 2;
        }
        x1 = (p >> 8) * (p >> 8);
        x1 = (x1 * 3038) >> 16;
        x2 = (-7357 * p) >> 16;
        p += (x1 + x2 + 3791) >> 4;

        self.pressure = @floatFromInt(p);
        return true;
    }

    pub fn _read_altitude(self: *Bmp180) !void {
        const temperatureOk = self._read_temperature();
        const pressureOk = self.read_pressure();
        if (!temperatureOk) return BMP180Error.TemperatureReadFailed;
        if (!pressureOk) return BMP180Error.PressureReadFailed;

        self.altitude = 44330.0 *
            (1.0 - std.math.pow(f32, self.pressure / SEALEVEL_PRESSURE, 0.1903));

        std.debug.print("Temperature: {d} °C\n", .{self.temperature});
        std.debug.print("Pressure: {d} Pa\n", .{self.pressure});
        std.debug.print("Altitude: {d} m\n", .{self.altitude});
        std.debug.print("\n", .{});
    }
};
