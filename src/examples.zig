const std = @import("std");
const Led = @import("led.zig").Led;
const Gpio = @import("pigpio.zig").Gpio;
const I2C = @import("pigpio.zig").I2C;
const Mpu6050 = @import("mpu6050.zig").Mpu6050;
const Hmc5883l = @import("hmc5883l.zig").Hmc5883l;
const Servo = @import("servo.zig").Servo;

pub const Examples = struct {
    const blinkyLed =
        Led{
        .pin = 19,
        .pwm = false,
        .setup = Gpio.init,
        .cleanup = Gpio.cleanup,
        .set = Gpio.set,
    };
    const pulseyLed =
        Led{
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
        .write = I2C.write_byte,
        .read = I2C.read_byte,
        .file_descriptor = &file_descriptor,
    };
    var hmc =
        Hmc5883l{
        .setup = I2C.init,
        .cleanup = I2C.cleanup,
        .write = I2C.write_byte,
        .read = I2C.read_byte,
        .file_descriptor = &file_descriptor,
    };
    const servo =
        Servo{
        .pin = 19,
        .setup = Gpio.init_servo,
        .cleanup = Gpio.cleanup,
        .set = Gpio.set_servo,
    };

    pub fn blinky() void {
        blinkyLed._setup();

        while (true) {
            std.time.sleep(400_000_000);
            blinkyLed._set(1);
            std.time.sleep(400_000_000);
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

    pub fn hmc5883l() !void {
        try hmc._setup();

        while (true) {
            hmc._read();
            std.time.sleep(1_000_000_000);
        }

        hmc._cleanup();
    }

    pub fn servo_loop() void {
        servo._setup();

        while (true) {
            servo._set(0);
            std.time.sleep(1_000_000_000);
            servo._set(90);
            std.time.sleep(1_000_000_000);
            servo._set(180);
            std.time.sleep(1_000_000_000);
            servo._set(90);
            std.time.sleep(1_000_000_000);
        }
    }
};
