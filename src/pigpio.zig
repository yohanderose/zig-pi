const std = @import("std");
const PWM_RANGE = @import("utils.zig").PWM_RANGE;
const I2CError = @import("errors.zig").I2CError;

const c = @cImport({
    @cInclude("pigpio.h");
});

pub fn init() i32 {
    return c.gpioInitialise();
}

pub fn terminate() void {
    _ = c.gpioTerminate();
}

pub const Gpio = struct {
    pub fn init(pin: u32) void {
        _ = c.gpioSetMode(pin, c.PI_OUTPUT);
    }

    pub fn set(pin: u32, value: u32) void {
        _ = c.gpioWrite(pin, value);
    }

    pub fn init_pwm(pin: u32) void {
        _ = c.gpioSetMode(pin, c.PI_OUTPUT);
        _ = c.gpioSetPWMrange(pin, PWM_RANGE);
    }

    pub fn set_pwm(pin: u32, value: u32) void {
        _ = c.gpioPWM(pin, std.math.clamp(value, 0, PWM_RANGE));
    }

    pub fn cleanup(pin: u32) void {
        _ = c.gpioSetMode(pin, c.PI_INPUT);
    }
};

pub const I2C = struct {
    pub fn init(device_address: c_uint) !u8 {
        const file_descriptor = c.i2cOpen(1, device_address, 0);
        if (file_descriptor < 0) return I2CError.I2COpenFailed;
        return @intCast(file_descriptor);
    }

    pub fn cleanup(file_descriptor: c_uint) void {
        _ = c.i2cClose(file_descriptor);
    }

    pub fn write_byte(file_descriptor: c_uint, addr: c_uint, data: c_uint) !void {
        _ = c.i2cWriteByteData(file_descriptor, addr, data);
        if (c.i2cReadByteData(file_descriptor, addr) < 0) return I2CError.I2CWriteFailed;
    }

    pub fn read_byte(file_descriptor: c_uint, addr: c_uint) !u8 {
        const data: u8 = @as(u8, @intCast(c.i2cReadByteData(file_descriptor, addr)));
        if (data < 0) return I2CError.I2CReadFailed;
        return data;
    }
};
