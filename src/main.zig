const std = @import("std");
const os = std.os;
const led = @import("led.zig");
const PWM_RANGE = led.PWM_RANGE;
const Led = led.Led;

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

pub fn main() !void {
    std.debug.print("Starting ... Press Ctrl+C to exit\n", .{});
    if (c.gpioInitialise() < 0) return std.debug.print("Failed to initialize pigpio\n", .{});

    const act = os.linux.Sigaction{
        .handler = .{ .handler = sigint_handler },
        .mask = os.linux.empty_sigset,
        .flags = 0,
    };
    if (os.linux.sigaction(os.linux.SIG.INT, &act, null) != 0) {
        return error.SignalHandlerError;
    }

    pulsey();
    // blinky();
    cleanup();
}
