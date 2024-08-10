const std = @import("std");
const os = std.os;
const led = @import("led.zig");
const PWM_RANGE = led.PWM_RANGE;
const Led = led.Led;
const mpu6050 = @import("mpu6050.zig");
const Mpu6050 = mpu6050.Mpu6050;
const I2CError = @import("errors.zig").I2CError;

const c = @cImport({
    @cInclude("pigpio.h");
});

fn gpio_norm_init(pin: u32) void {
    _ = c.gpioSetMode(pin, c.PI_OUTPUT);
}

fn gpio_norm_set(pin: u32, value: u32) void {
    // std.debug.print("Device on pin {} set to {}\n", .{ pin, value });
    _ = c.gpioWrite(pin, value);
}

fn gpio_pwm_init(pin: u32) void {
    _ = c.gpioSetMode(pin, c.PI_OUTPUT);
    _ = c.gpioSetPWMrange(pin, PWM_RANGE);
}

fn gpio_pwm_set(pin: u32, value: u32) void {
    _ = c.gpioPWM(pin, std.math.clamp(value, 0, PWM_RANGE));
}

fn gpio_cleanup(pin: u32) void {
    _ = c.gpioSetMode(pin, c.PI_INPUT);
}

const devices = [_]Led{
    Led{
        .name = "LED1",
        .pin = 19,
        .pwm = true,
        .setup = gpio_pwm_init,
        .cleanup = gpio_cleanup,
        .set = gpio_pwm_set,
    },
};

fn cleanup() void {
    std.debug.print("Exiting ...\n", .{});
    for (devices) |dev| {
        dev._cleanup();
    }
    _ = c.gpioTerminate();
    std.process.exit(0);
}

fn sigint_handler(sig: c_int) callconv(.C) void {
    std.debug.print("SIGINT received\n", .{});
    _ = sig;
    cleanup();
}

fn blinky() void {
    for (devices) |dev| {
        dev._setup();
    }

    while (true) {
        std.time.sleep(900_000_000);
        for (devices) |dev| {
            dev._set(1);
        }
        std.time.sleep(900_000_000);
        for (devices) |dev| {
            dev._set(0);
        }
    }
}

fn pulsey() void {
    for (devices) |dev| {
        dev._setup();
    }

    var i: f32 = 0;
    const percent_max = 1;

    while (true) {
        i = 0;

        while (i < percent_max) : (i += 0.01) {
            for (devices) |dev| {
                dev._set(i);
            }
            std.time.sleep(900_000);
        }

        while (i > 0) : (i -= 0.01) {
            for (devices) |dev| {
                dev._set(i);
            }
            std.time.sleep(900_000);
        }
    }
}

fn i2c_init(device_address: c_uint) !u8 {
    const file_descriptor = c.i2cOpen(1, device_address, 0);
    if (file_descriptor < 0) return I2CError.I2COpenFailed;
    return @intCast(file_descriptor);
}

fn i2c_cleanup(file_descriptor: c_uint) void {
    _ = c.i2cClose(file_descriptor);
}

fn i2c_write_data(file_descriptor: c_uint, addr: c_uint, data: c_uint) !void {
    _ = c.i2cWriteByteData(file_descriptor, addr, data);
    if (c.i2cReadByteData(file_descriptor, addr) < 0) return I2CError.I2CWriteFailed;
}

fn i2c_read_data(file_descriptor: c_uint, addr: c_uint) !u16 {
    const high_byte: u16 = @as(u16, @intCast(c.i2cReadByteData(file_descriptor, addr)));
    const low_byte: u16 = @as(u16, @intCast(c.i2cReadByteData(file_descriptor, addr + 1)));
    if (high_byte < 0 or low_byte < 0) return I2CError.I2CReadFailed;
    return (high_byte << 8) | low_byte;
}

pub fn main() !void {
    std.debug.print("Starting ... Press Ctrl+C to exit\n", .{});
    if (c.gpioInitialise() < 0)
        return std.debug.print("Failed to initialize pigpio\n", .{});

    const act = os.linux.Sigaction{
        .handler = .{ .handler = sigint_handler },
        .mask = os.linux.empty_sigset,
        .flags = 0,
    };
    if (os.linux.sigaction(os.linux.SIG.INT, &act, null) != 0) {
        return error.SignalHandlerError;
    }

    var file_descriptor: c_uint = 0;
    var mpu = Mpu6050{
        .setup = i2c_init,
        .cleanup = i2c_cleanup,
        .write = i2c_write_data,
        .read = i2c_read_data,
        .file_descriptor = &file_descriptor,
    };
    try mpu._setup();

    while (true) {
        try mpu._read();
        std.time.sleep(1_000_000_000);
    }

    mpu._cleanup();
    // pulsey();
    // blinky();
}
