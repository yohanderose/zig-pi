const std = @import("std");
const os = std.os;
const pigpio = @import("pigpio.zig");
const Gpio = pigpio.Gpio;
const I2C = pigpio.I2C;
const led = @import("led.zig");
const PWM_RANGE = @import("utils.zig").PWM_RANGE;
const Led = led.Led;
const mpu6050 = @import("mpu6050.zig");
const Mpu6050 = mpu6050.Mpu6050;
const I2CError = @import("errors.zig").I2CError;

const devices = [_]Led{
    Led{
        .name = "LED1",
        .pin = 19,
        .pwm = true,
        .setup = Gpio.init_pwm,
        .cleanup = Gpio.cleanup,
        .set = Gpio.set_pwm,
    },
};

fn cleanup() void {
    std.debug.print("Exiting ...\n", .{});
    for (devices) |dev| {
        dev._cleanup();
    }
    pigpio.terminate();
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

pub fn main() !void {
    std.debug.print("Starting ... Press Ctrl+C to exit\n", .{});
    if (pigpio.init() < 0)
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
        .setup = I2C.init,
        .cleanup = I2C.cleanup,
        .write = I2C.write_data,
        .read = I2C.read_data,
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
