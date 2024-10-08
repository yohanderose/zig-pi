const std = @import("std");
const Gpio = @import("pigpio.zig").Gpio;
const I2C = @import("pigpio.zig").I2C;
const SimpleOutput = @import("led.zig").SimpleOutput;
const Servo = @import("servo.zig").Servo;
const Mpu6050 = @import("mpu6050.zig").Mpu6050;
const Hmc5883l = @import("hmc5883l.zig").Hmc5883l;
const Bmp180 = @import("bmp180.zig").Bmp180;

pub const Examples = struct {
    var mpu_file_descriptor: c_uint = 0;
    var hmc_file_descriptor: c_uint = 0;
    var bmp_file_descriptor: c_uint = 0;

    pub var Devices = struct {
        blinky: SimpleOutput =
            SimpleOutput{
                .pin = 19,
                .pwm = false,
                .setup = Gpio.init,
                .cleanup = Gpio.cleanup,
                .set = Gpio.set,
            },
        pulsey: SimpleOutput =
            SimpleOutput{
                .pin = 19,
                .pwm = true,
                .setup = Gpio.init_pwm,
                .cleanup = Gpio.cleanup,
                .set = Gpio.set_pwm,
            },
        motor: SimpleOutput =
            SimpleOutput{
                .pin = 19,
                .pwm = true,
                .setup = Gpio.init_pwm,
                .cleanup = Gpio.cleanup,
                .set = Gpio.set_pwm,
            },
        servo: Servo =
            Servo{
                .pin = 19,
                .setup = Gpio.init_servo,
                .cleanup = Gpio.cleanup,
                .set = Gpio.set_servo,
            },
        mpu: Mpu6050 =
            Mpu6050{
                .setup = I2C.init,
                .cleanup = I2C.cleanup,
                .write = I2C.write_byte,
                .read = I2C.read_byte,
                .file_descriptor = &mpu_file_descriptor,
            },
        hmc: Hmc5883l =
            Hmc5883l{
                .setup = I2C.init,
                .cleanup = I2C.cleanup,
                .write = I2C.write_byte,
                .read = I2C.read_byte,
                .file_descriptor = &hmc_file_descriptor,
            },
        bmp180: Bmp180 =
            Bmp180{
                .is_active = false,
                .setup = I2C.init,
                .cleanup = I2C.cleanup,
                .write = I2C.write_byte,
                .read = I2C.read_byte,
                .file_descriptor = &bmp_file_descriptor,
            },
    }{};

    pub fn cleanup() void {
        if (Devices.blinky.is_active) Devices.blinky._cleanup();
        if (Devices.pulsey.is_active) Devices.pulsey._cleanup();
        if (Devices.motor.is_active) Devices.motor._cleanup();
        if (Devices.servo.is_active) Devices.servo._cleanup();
        if (Devices.mpu.is_active) Devices.mpu._cleanup();
        if (Devices.hmc.is_active) Devices.hmc._cleanup();
    }

    pub fn blinky() void {
        Devices.blinky._setup();

        while (true) {
            std.time.sleep(200_000_000);
            Devices.blinky._set(1);
            std.time.sleep(200_000_000);
            Devices.blinky._set(0);
        }
    }

    pub fn pulsey() void {
        Devices.pulsey._setup();
        var i: f32 = 0;
        const percent_max = 1;

        while (true) {
            i = 0;

            while (i < percent_max) : (i += 0.01) {
                Devices.pulsey._set(i);
                std.time.sleep(1_200_000);
            }

            while (i > 0) : (i -= 0.01) {
                Devices.pulsey._set(i);
                std.time.sleep(1_200_000);
            }
        }
    }

    pub fn motor() void {
        Devices.motor._setup();
        var i: i32 = 0;

        while (true) {
            while (i < 60) : (i += 1) {
                const percent = @as(f32, @floatFromInt(i)) / 100;
                Devices.motor._set(percent);
                std.debug.print("Setting motor to {}%\n", .{i});
                std.time.sleep(2_000_000_000);
            }

            Devices.motor._set(0);
            std.time.sleep(5_000_000_000);
        }
    }

    pub fn servo_loop() void {
        Devices.servo._setup();

        while (true) {
            Devices.servo._set(0);
            std.time.sleep(1_000_000_000);
            Devices.servo._set(90);
            std.time.sleep(1_000_000_000);
            Devices.servo._set(180);
            std.time.sleep(1_000_000_000);
            Devices.servo._set(90);
            std.time.sleep(1_000_000_000);
        }
    }

    pub fn mpu6050() !void {
        try Devices.mpu._setup();

        while (true) {
            try Devices.mpu._read();
            std.time.sleep(1_000_000_000);
        }

        Devices.mpu._cleanup();
    }

    pub fn hmc5883l() !void {
        try Devices.hmc._setup();

        while (true) {
            Devices.hmc._read();
            std.time.sleep(1_000_000_000);
        }

        Devices.hmc._cleanup();
    }

    pub fn bmp180() !void {
        try Devices.bmp180._setup();

        while (true) {
            try Devices.bmp180._read_altitude();
            std.time.sleep(1_000_000_000);
        }

        Devices.bmp180._cleanup();
    }
};
