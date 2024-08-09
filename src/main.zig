const std = @import("std");
const os = std.os;

const c = @cImport({
    @cInclude("pigpio.h");
});

const LED_PIN = 26;

fn cleanup() void {
    std.debug.print("Exiting ...\n", .{});
    _ = c.gpioSetMode(LED_PIN, c.PI_INPUT);
    _ = c.gpioTerminate();
    std.process.exit(0);
}

fn sigintHandler(sig: c_int) callconv(.C) void {
    std.debug.print("SIGINT received\n", .{});
    _ = sig;
    cleanup();
}

pub fn main() !void {
    std.debug.print("Starting ... Press Ctrl+C to exit\n", .{});
    const act = os.linux.Sigaction{
        .handler = .{ .handler = sigintHandler },
        .mask = os.linux.empty_sigset,
        .flags = 0,
    };

    if (os.linux.sigaction(os.linux.SIG.INT, &act, null) != 0) {
        return error.SignalHandlerError;
    }

    if (c.gpioInitialise() < 0) return std.debug.print("Failed to initialize pigpio\n", .{});
    _ = c.gpioSetMode(LED_PIN, c.PI_OUTPUT);

    while (true) {
        _ = c.gpioWrite(LED_PIN, c.PI_HIGH);
        std.time.sleep(100_000_000);
        _ = c.gpioWrite(LED_PIN, c.PI_LOW);
        std.time.sleep(100_000_000);
    }

    cleanup();
}
