/**
 * this file is part of amigahid-pico, (c) 2021 just nine <nine@aphlor.org>
 * LED status indicator module
 */

#include "led_status.h"
#include "hardware/gpio.h"
#include "pico/time.h"

// Activity LED on-time in milliseconds
#define ACTIVITY_LED_DURATION_MS 50

static absolute_time_t activity_off_time;
static bool activity_led_active = false;

void led_status_init(void)
{
    // Initialize LED1 (Status)
    gpio_init(LED1_PIN);
    gpio_set_dir(LED1_PIN, GPIO_OUT);
    gpio_put(LED1_PIN, 0);

    // Initialize LED2 (Activity)
    gpio_init(LED2_PIN);
    gpio_set_dir(LED2_PIN, GPIO_OUT);
    gpio_put(LED2_PIN, 0);

    activity_led_active = false;
}

void led_status_on(void)
{
    gpio_put(LED1_PIN, 1);
}

void led_status_off(void)
{
    gpio_put(LED1_PIN, 0);
}

void led_activity_trigger(void)
{
    gpio_put(LED2_PIN, 1);
    activity_off_time = make_timeout_time_ms(ACTIVITY_LED_DURATION_MS);
    activity_led_active = true;
}

void led_status_task(void)
{
    if (activity_led_active && time_reached(activity_off_time)) {
        gpio_put(LED2_PIN, 0);
        activity_led_active = false;
    }
}
