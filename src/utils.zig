pub const PWM_RANGE = 255;

pub const DeviceTypes = enum {
    Led,
    Mpu6050,
    Hmc5883l,
    Bmp180,
    Servo,
};

pub const UVec3 = struct {
    x: u16,
    y: u16,
    z: u16,
};

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};
