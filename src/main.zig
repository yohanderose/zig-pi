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

const Examples = @import("examples.zig").Examples;

fn cleanup() void {
    std.debug.print("Exiting ...\n", .{});
    pigpio.terminate();
    std.process.exit(0);
}

fn sigint_handler(sig: c_int) callconv(.C) void {
    std.debug.print("SIGINT received\n", .{});
    _ = sig;
    cleanup();
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

    // Examples.pulsey();
    // Examples.blinky();
    try Examples.mpu6050();
}
