const std = @import("std");
const DeviceTypes = @import("utils.zig").DeviceTypes;
const PWM_RANGE = @import("utils.zig").PWM_RANGE;

pub const Servo = struct {
    is_active: bool = false,
    pin: u32,
    setup: *const fn (u32) void,
    cleanup: *const fn (u32) void,
    set: *const fn (u32, f32) void,

    pub fn _setup(self: *Servo) void {
        self.setup(self.pin);
        self.is_active = true;
    }

    pub fn _cleanup(self: *Servo) void {
        self.cleanup(self.pin);
    }

    pub fn _set(self: *Servo, value: f32) void {
        self.set(self.pin, value);
    }
};
