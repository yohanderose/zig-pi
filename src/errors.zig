pub const I2CError = error{
    I2COpenFailed,
    I2CWriteFailed,
    I2CReadFailed,
};

pub const BMP180Error = error{
    CalibrationReadFailed,
    TemperatureReadFailed,
    PressureReadFailed,
};
