const std = @import("std");
const Led = @import("led.zig").Led;
const Gpio = @import("pigpio.zig").Gpio;
const I2C = @import("pigpio.zig").I2C;
const Mpu6050 = @import("mpu6050.zig").Mpu6050;

pub const Examples = struct {
    const blinkyLed =
        Led{
        .name = "LED1",
        .pin = 19,
        .pwm = false,
        .setup = Gpio.init,
        .cleanup = Gpio.cleanup,
        .set = Gpio.set,
    };
    const pulseyLed =
        Led{
        .name = "LED2",
        .pin = 19,
        .pwm = true,
        .setup = Gpio.init_pwm,
        .cleanup = Gpio.cleanup,
        .set = Gpio.set_pwm,
    };
    var file_descriptor: c_uint = 0;
    var mpu = Mpu6050{
        .setup = I2C.init,
        .cleanup = I2C.cleanup,
        .write = I2C.write_data,
        .read = I2C.read_data,
        .file_descriptor = &file_descriptor,
    };

    pub fn blinky() void {
        blinkyLed._setup();

        while (true) {
            std.time.sleep(900_000_000);
            blinkyLed._set(1);
            std.time.sleep(900_000_000);
            blinkyLed._set(0);
        }
    }

    pub fn pulsey() void {
        pulseyLed._setup();
        var i: f32 = 0;
        const percent_max = 1;

        while (true) {
            i = 0;

            while (i < percent_max) : (i += 0.01) {
                pulseyLed._set(i);
                std.time.sleep(900_000);
            }

            while (i > 0) : (i -= 0.01) {
                pulseyLed._set(i);
                std.time.sleep(900_000);
            }
        }
    }

    pub fn mpu6050() !void {
        try mpu._setup();

        while (true) {
            try mpu._read();
            std.time.sleep(1_000_000_000);
        }

        mpu._cleanup();
    }
};
