const std = @import("std");
const utils = @import("utils.zig");
const DeviceTypes = utils.DeviceTypes;
const UVec3 = utils.UVec3;
const Vec3 = utils.Vec3;

const DEVICE_ADDRESS = 0x68; // Identifier for MPU6050
const PWR_MGMT_1 = 0x6B;
const SMPLRT_DIV = 0x19;
const CONFIG = 0x1A;
const GYRO_CONFIG = 0x1B;
const INT_ENABLE = 0x38;
const ACCEL_XOUT_H = 0x3B;
const ACCEL_YOUT_H = 0x3D;
const ACCEL_ZOUT_H = 0x3F;
const GYRO_XOUT_H = 0x43;
const GYRO_YOUT_H = 0x45;
const GYRO_ZOUT_H = 0x47;

// Python and C implementation, and wiring diagram:
// https://www.electronicwings.com/raspberry-pi/mpu6050-accelerometergyroscope-interfacing-with-raspberry-pi
pub const Mpu6050 = struct {
    is_active: bool = false,
    setup: *const fn (c_uint) anyerror!u8,
    cleanup: *const fn (c_uint) void,
    write: *const fn (c_uint, c_uint, c_uint) anyerror!void,
    read: *const fn (c_uint, c_uint) anyerror!u8,
    file_descriptor: *c_uint,
    sensitivity: f32 = 16384.0,
    raw_acc: UVec3 = UVec3{ .x = 0, .y = 0, .z = 0 },
    raw_gyro: UVec3 = UVec3{ .x = 0, .y = 0, .z = 0 },
    acc: Vec3 = Vec3{ .x = 0, .y = 0, .z = 0 },
    gyro: Vec3 = Vec3{ .x = 0, .y = 0, .z = 0 },

    pub fn _setup(self: *Mpu6050) !void {
        self.file_descriptor.* = try self.setup(DEVICE_ADDRESS);

        // Initialize MPU6050 specific registers
        try self.write(self.file_descriptor.*, SMPLRT_DIV, 0x07);
        try self.write(self.file_descriptor.*, PWR_MGMT_1, 0x01);
        try self.write(self.file_descriptor.*, CONFIG, 0);
        try self.write(self.file_descriptor.*, GYRO_CONFIG, 24);
        try self.write(self.file_descriptor.*, INT_ENABLE, 1);

        self.is_active = true;
    }

    pub fn _cleanup(self: *Mpu6050) void {
        self.cleanup(self.file_descriptor.*);
    }

    fn read_sensor(self: *Mpu6050, file_descriptor: c_uint, addr: c_uint) u16 {
        const high_byte: u16 = @as(u16, self.read(file_descriptor, addr) catch 0);
        const low_byte: u16 = @as(u16, self.read(file_descriptor, addr + 1) catch 0);
        return (high_byte << 8) | low_byte;
    }

    pub fn _read(self: *Mpu6050) void {
        self.raw_acc.x = self.read_sensor(self.file_descriptor.*, ACCEL_XOUT_H);
        self.raw_acc.y = self.read_sensor(self.file_descriptor.*, ACCEL_YOUT_H);
        self.raw_acc.z = self.read_sensor(self.file_descriptor.*, ACCEL_ZOUT_H);

        self.raw_gyro.x = self.read_sensor(self.file_descriptor.*, GYRO_XOUT_H);
        self.raw_gyro.y = self.read_sensor(self.file_descriptor.*, GYRO_YOUT_H);
        self.raw_gyro.z = self.read_sensor(self.file_descriptor.*, GYRO_ZOUT_H);

        self.acc.x = @as(f32, @floatFromInt(self.raw_acc.x)) / self.sensitivity;
        self.acc.y = @as(f32, @floatFromInt(self.raw_acc.y)) / self.sensitivity;
        self.acc.z = @as(f32, @floatFromInt(self.raw_acc.z)) / self.sensitivity;

        self.gyro.x = @as(f32, @floatFromInt(self.raw_gyro.x)) / self.sensitivity;
        self.gyro.y = @as(f32, @floatFromInt(self.raw_gyro.y)) / self.sensitivity;
        self.gyro.z = @as(f32, @floatFromInt(self.raw_gyro.z)) / self.sensitivity;

        std.debug.print("Acc: ({}, {}, {})\n", .{ self.acc.x, self.acc.y, self.acc.z });
        std.debug.print("Gyro: ({}, {}, {})\n", .{ self.gyro.x, self.gyro.y, self.gyro.z });
    }
};
