#include <signal.h>
#include <stdio.h>
#include <pigpio.h>

const int LED_PIN = 26;
volatile sig_atomic_t signal_received = 0;
void sigint_handler(int signal) {
   signal_received = signal;
}

int main() {
   if (gpioInitialise() == PI_INIT_FAILED) {
      printf("ERROR: Failed to initialize the GPIO interface.\n");
      return 1;
   }
   gpioSetMode(LED_PIN, PI_OUTPUT);
   signal(SIGINT, sigint_handler);
   printf("Press CTRL-C to exit.\n");
   while (!signal_received) {
      gpioWrite(LED_PIN, PI_HIGH);
      time_sleep(0.3);
      gpioWrite(LED_PIN, PI_LOW);
      time_sleep(0.3);
   }
   gpioSetMode(LED_PIN, PI_INPUT);
   gpioTerminate();
   printf("\n");
   return 0;
}
