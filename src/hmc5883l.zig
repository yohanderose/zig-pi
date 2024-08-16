const std = @import("std");
const utils = @import("utils.zig");
const DeviceTypes = utils.DeviceTypes;
const UVec3 = utils.UVec3;
const Vec3 = utils.Vec3;

const HMC5883L_ADDRESS = 0x1E;
const QMC5883_ADDRESS = 0x0D;
const VCM5883L_ADDRESS = 0x0C;

const IC_NONE = 0;
const IC_HMC5883L = 1;
const IC_QMC5883 = 2;
const IC_VCM5883L = 3;
const IC_ERROR = 4;

const HMC5883L_REG_CONFIG_A = 0x00;
const HMC5883L_REG_CONFIG_B = 0x01;
const HMC5883L_REG_MODE = 0x02;
const HMC5883L_REG_OUT_X_M = 0x03;
const HMC5883L_REG_OUT_X_L = 0x04;
const HMC5883L_REG_OUT_Z_M = 0x05;
const HMC5883L_REG_OUT_Z_L = 0x06;
const HMC5883L_REG_OUT_Y_M = 0x07;
const HMC5883L_REG_OUT_Y_L = 0x08;
const HMC5883L_REG_STATUS = 0x09;
const HMC5883L_REG_IDENT_A = 0x0A;
const HMC5883L_REG_IDENT_B = 0x0B;
const HMC5883L_REG_IDENT_C = 0x0C;

const QMC5883_REG_OUT_X_M = 0x01;
const QMC5883_REG_OUT_X_L = 0x00;
const QMC5883_REG_OUT_Z_M = 0x05;
const QMC5883_REG_OUT_Z_L = 0x04;
const QMC5883_REG_OUT_Y_M = 0x03;
const QMC5883_REG_OUT_Y_L = 0x02;
const QMC5883_REG_STATUS = 0x06;
const QMC5883_REG_CONFIG_1 = 0x09;
const QMC5883_REG_CONFIG_2 = 0x0A;
const QMC5883_REG_IDENT_B = 0x0B;
const QMC5883_REG_IDENT_C = 0x20;
const QMC5883_REG_IDENT_D = 0x21;

const VCM5883L_REG_OUT_X_L = 0x00;
const VCM5883L_REG_OUT_X_H = 0x01;
const VCM5883L_REG_OUT_Y_L = 0x02;
const VCM5883L_REG_OUT_Y_H = 0x03;
const VCM5883L_REG_OUT_Z_L = 0x04;
const VCM5883L_REG_OUT_Z_H = 0x05;
const VCM5883L_CTR_REG1 = 0x0B;
const VCM5883L_CTR_REG2 = 0x0A;

// This chip is often falsely labelled as HMC5883L, but it is actually a QMC5883
// https://github.com/DFRobot/DFRobot_QMC5883/blob/master/DFRobot_QMC5883.cpp
pub const Hmc5883l = struct {
    type: DeviceTypes = DeviceTypes.Hmc5883l,
    setup: *const fn (c_uint) anyerror!u8,
    cleanup: *const fn (c_uint) void,
    write: *const fn (c_uint, c_uint, c_uint) anyerror!void,
    read: *const fn (c_uint, c_uint) anyerror!u8,
    file_descriptor: *c_uint,
    data: Vec3 = Vec3{ .x = 0, .y = 0, .z = 0 },
    declination_angle: f32 = 0.0,
    heading_deg: f32 = 0.0,

    pub fn _setup(self: *Hmc5883l) !void {
        self.file_descriptor.* = try self.setup(QMC5883_ADDRESS);

        // Initialise QMC5883 specific registers
        try self.write(self.file_descriptor.*, QMC5883_REG_IDENT_B, 0x01);
        try self.write(self.file_descriptor.*, QMC5883_REG_IDENT_C, 0x40);
        try self.write(self.file_descriptor.*, QMC5883_REG_IDENT_D, 0x01);
        try self.write(self.file_descriptor.*, QMC5883_REG_CONFIG_1, 0x1D);
    }

    pub fn _cleanup(self: *Hmc5883l) void {
        self.cleanup(self.file_descriptor.*);
    }

    fn read_sensor(self: *Hmc5883l, addr: c_uint) f32 {
        const high_byte: u16 = @as(u16, self.read(self.file_descriptor.*, addr) catch 0);
        const low_byte: u16 = @as(u16, self.read(self.file_descriptor.*, addr + 1) catch 0);
        var value: f32 = @as(f32, @floatFromInt((high_byte << 8) | low_byte));
        if (value > 32767) value -= 65536;
        return value;
    }

    pub fn _read(self: *Hmc5883l) void {
        self.data.x = self.read_sensor(QMC5883_REG_OUT_X_L);
        self.data.y = self.read_sensor(QMC5883_REG_OUT_Y_L);
        self.data.z = self.read_sensor(QMC5883_REG_OUT_Z_L);

        var heading = std.math.atan2(self.data.y, self.data.x) + self.declination_angle;
        if (heading < 0) heading += 2 * std.math.pi;
        if (heading > 2 * std.math.pi) heading -= 2 * std.math.pi;

        self.heading_deg = heading * 180 / std.math.pi;
        std.debug.print("Heading: {d}°\n", .{self.heading_deg});
    }
};
