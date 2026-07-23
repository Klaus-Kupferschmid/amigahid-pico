/**
 * this file is part of amigahid-pico, (c) 2021 just nine <nine@aphlor.org>
 * LED status indicator module
 *
 * LED1 (GP25): Power/Status - always on when running
 * LED2 (GP16): Activity - blinks on USB keyboard events
 */

#ifndef _LED_STATUS_H
#define _LED_STATUS_H

#include <stdint.h>

// LED pin definitions (matching REV5 / Amiga-HID rev1.0)
#ifndef LED1_PIN
#  define LED1_PIN 25   // GP25 - Status LED (Pico convention)
#endif
#ifndef LED2_PIN
#  define LED2_PIN 16   // GP16 - Activity LED (Tiny-Board convention)
#endif

/**
 * Initialize LED GPIOs
 */
void led_status_init(void);

/**
 * Turn on status LED (LED1)
 */
void led_status_on(void);

/**
 * Turn off status LED (LED1)
 */
void led_status_off(void);

/**
 * Trigger activity blink on LED2
 * Non-blocking: sets LED on and schedules off via led_status_task()
 */
void led_activity_trigger(void);

/**
 * Service routine - call from main loop
 * Handles activity LED timeout
 */
void led_status_task(void);

#endif // _LED_STATUS_H
