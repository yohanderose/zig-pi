## Dependencies

**The `make install` command will install the following dependencies on the Pi.**

- [zig](https://ziglang.org/download/)
- [pigpio](http://abyz.me.uk/rpi/pigpio/download.html)
- **Note**: To use I2C, you need to enable it in `raspi-config` and install the `i2c-tools` package.

  ```bash
  sudo apt-get install i2c-tools
  sudo raspi-config
  ```

## Usage

- SSH into the Pi, clone and navigate into the project.

```bash
sudo su
eval $(make env)
make install # for zig 0.13 and pigpio-master (actually develop branch)
make
```

## Run

```bash
sudo su
eval $(make env)
./main
```

## Development

Make changes to the code on your host machine and rsync them to the Pi with

```bash
make push
```

Or grab quick changes made on the Pi with

```bash
make pull
```
