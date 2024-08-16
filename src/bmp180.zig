const std = @import("std");
const utils = @import("utils.zig");
const DeviceTypes = utils.DeviceTypes;
const UVec3 = utils.UVec3;
const Vec3 = utils.Vec3;

const DEVICE_ADDRESS = 0x1d; // Identifier for HMC5883L
const REG_A = 0x0B;
const REG_B = 0x09;
const MODE = 0x02;
const X_AXIS_H = 0x03;
const Z_AXIS_H = 0x05;
const Y_AXIS_H = 0x07;

pub const Hmc5883l = struct {
    type: DeviceTypes = DeviceTypes.Hmc5883l,
    setup: *const fn (c_uint) anyerror!u8,
    cleanup: *const fn (c_uint) void,
    write: *const fn (c_uint, c_uint, c_uint) anyerror!void,
    read: *const fn (c_uint, c_uint) anyerror!u8,
    file_descriptor: *c_uint,
    declination: f32 = -0.00669,
    data: Vec3 = Vec3{ .x = 0, .y = 0, .z = 0 },

    pub fn _setup(self: *Hmc5883l) !void {
        self.file_descriptor.* = try self.setup(DEVICE_ADDRESS);

        // Initialize HMC5883L specific registers
        try self.write(self.file_descriptor.*, REG_A, 0x01);
        try self.write(self.file_descriptor.*, REG_B, 0x1D);
        try self.write(self.file_descriptor.*, MODE, 0x00);
    }

    pub fn _cleanup(self: *Hmc5883l) void {
        self.cleanup(self.file_descriptor.*);
    }

    fn read_sensor(self: *Hmc5883l, file_descriptor: c_uint, addr: c_uint) f32 {
        const high_byte: u16 = @as(u16, self.read(file_descriptor, addr) catch 0);
        const low_byte: u16 = @as(u16, self.read(file_descriptor, addr + 1) catch 0);
        var value: f32 = @as(f32, @floatFromInt((high_byte << 8) | low_byte));
        if (value > 32767) value -= 65536;
        return value;
    }

    pub fn _read(self: *Hmc5883l) void {
        self.data.x = self.read_sensor(self.file_descriptor.*, X_AXIS_H);
        self.data.z = self.read_sensor(self.file_descriptor.*, Z_AXIS_H);
        self.data.y = self.read_sensor(self.file_descriptor.*, Y_AXIS_H);

        var heading = std.math.atan2(self.data.y, self.data.x) + self.declination;
        if (heading > 2 * std.math.pi) heading -= 2 * std.math.pi;
        if (heading < 0) heading += 2 * std.math.pi;

        const heading_deg = heading * 180 / std.math.pi;
        std.debug.print("Heading: {}°\n", .{heading_deg});
    }
};
