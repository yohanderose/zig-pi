const std = @import("std");
const pigpio = @import("pigpio.zig");
const os = std.os;

const Examples = @import("examples.zig").Examples;

fn cleanup() void {
    std.debug.print("Exiting ...\n", .{});
    Examples.cleanup();
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

    // Examples.blinky();
    // Examples.pulsey();
    Examples.servo_loop();
    // try Examples.mpu6050(); // imu
    // try Examples.hmc5883l();  // compass
    // try Examples.bmp180(); // barometer
}
