add_executable(test_leds
    main.c
)

target_link_libraries(test_leds
    pico_stdlib
    hardware_gpio
)

pico_add_extra_outputs(test_leds)
