/**
 * LED-Test für Amiga-HID rev1.0 Board
 * 
 * LED1 (Status):   GP25 - Pico-Konvention
 * LED2 (Activity): GP16 - Tiny-Board-Konvention
 * 
 * Testmuster:
 *   1. Beide LEDs an (1s)
 *   2. Nur LED1 an (500ms)
 *   3. Nur LED2 an (500ms)
 *   4. Abwechselndes Blinken (je 250ms)
 */

#include "pico/stdlib.h"
#include "hardware/gpio.h"

#define LED1_PIN 25   // GP25 - Status LED
#define LED2_PIN 16   // GP16 - Activity LED

int main(void) {
    // GPIO initialisieren
    gpio_init(LED1_PIN);
    gpio_init(LED2_PIN);
    gpio_set_dir(LED1_PIN, GPIO_OUT);
    gpio_set_dir(LED2_PIN, GPIO_OUT);

    // Startsequenz: Beide LEDs kurz an zum Testen
    gpio_put(LED1_PIN, 1);
    gpio_put(LED2_PIN, 1);
    sleep_ms(1000);

    // Nur LED1 (GP25)
    gpio_put(LED1_PIN, 1);
    gpio_put(LED2_PIN, 0);
    sleep_ms(500);

    // Nur LED2 (GP16)
    gpio_put(LED1_PIN, 0);
    gpio_put(LED2_PIN, 1);
    sleep_ms(500);

    // Endlos abwechselnd blinken
    while (1) {
        // LED1 an, LED2 aus
        gpio_put(LED1_PIN, 1);
        gpio_put(LED2_PIN, 0);
        sleep_ms(250);

        // LED1 aus, LED2 an
        gpio_put(LED1_PIN, 0);
        gpio_put(LED2_PIN, 1);
        sleep_ms(250);
    }

    return 0;
}
