const std = @import("std");
const PWM_RANGE = @import("utils.zig").PWM_RANGE;

pub const Led = struct {
    name: []const u8,
    pin: u32,
    pwm: bool,
    setup: *const fn (u32) void,
    cleanup: *const fn (u32) void,
    set: *const fn (u32, u32) void,

    pub fn _setup(self: Led) void {
        self.setup(self.pin);
    }

    pub fn _cleanup(self: Led) void {
        self.cleanup(self.pin);
    }

    pub fn _set(self: *const Led, percent: f32) void {
        if (self.pwm) return self.set(self.pin, @intFromFloat(percent * PWM_RANGE));
        return self.set(self.pin, @intFromBool(percent > 0));
    }
};
