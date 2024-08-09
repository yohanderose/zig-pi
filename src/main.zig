const std = @import("std");
const os = std.os;

const c = @cImport({
    @cInclude("pigpio.h");
});

const LED_PIN = 26;
const LED_PIN2 = 19;

fn cleanup() void {
    std.debug.print("Exiting ...\n", .{});
    _ = c.gpioSetMode(LED_PIN, c.PI_INPUT);
    _ = c.gpioSetMode(LED_PIN2, c.PI_INPUT);
    _ = c.gpioTerminate();
    std.process.exit(0);
}

fn sigintHandler(sig: c_int) callconv(.C) void {
    std.debug.print("SIGINT received\n", .{});
    _ = sig;
    cleanup();
}

fn blinky() void {
    while (true) {
        _ = c.gpioWrite(LED_PIN, c.PI_HIGH);
        _ = c.gpioWrite(LED_PIN2, c.PI_LOW);
        std.time.sleep(300_000_000);
        _ = c.gpioWrite(LED_PIN, c.PI_LOW);
        _ = c.gpioWrite(LED_PIN2, c.PI_HIGH);
        std.time.sleep(300_000_000);
    }
}

fn pulsey() void {
    var i: u32 = 0;
    // std.debug.print("Resetting previous PWM max {} to 1000", .{c.gpioGetPWMdutycycle(LED_PIN)});
    const max = 10000;
    _ = c.gpioSetPWMrange(LED_PIN, max);
    _ = c.gpioSetPWMrange(LED_PIN2, max);

    while (true) {
        i = 0;

        while (i < max) : (i += 1) {
            _ = c.gpioPWM(LED_PIN, i);
            _ = c.gpioPWM(LED_PIN2, i);
            std.time.sleep(200_000);
        }

        while (i > 0) : (i -= 1) {
            _ = c.gpioPWM(LED_PIN, i);
            _ = c.gpioPWM(LED_PIN2, i);
            std.time.sleep(200_000);
        }
    }
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
    _ = c.gpioSetMode(LED_PIN2, c.PI_OUTPUT);

    pulsey();
    cleanup();
}
