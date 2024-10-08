const std = @import("std");
const DeviceTypes = @import("utils.zig").DeviceTypes;
const PWM_RANGE = @import("utils.zig").PWM_RANGE;

pub const SimpleOutput = struct {
    is_active: bool = false,
    pin: u32,
    pwm: bool,
    setup: *const fn (u32) void,
    cleanup: *const fn (u32) void,
    set: *const fn (u32, u32) void,

    pub fn _setup(self: *SimpleOutput) void {
        self.setup(self.pin);
        self.is_active = true;
    }

    pub fn _cleanup(self: *SimpleOutput) void {
        self.cleanup(self.pin);
    }

    pub fn _set(self: *SimpleOutput, percent: f32) void {
        if (self.pwm) return self.set(self.pin, @intFromFloat(percent * PWM_RANGE));
        return self.set(self.pin, @intFromBool(percent > 0));
    }
};
