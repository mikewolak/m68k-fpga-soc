/*
 * M68K LED Blink Test
 * For j68_cpu M68000 SOC
 */

/* Hardware Definitions */
#define LED_BASE    ((volatile unsigned short *)0xFF000000)

/* LED bits */
#define LED1  (1 << 0)
#define LED2  (1 << 1)

/* Simple delay function */
void delay(unsigned int count) {
    volatile unsigned int i;
    for (i = 0; i < count; i++) {
        /* Busy wait */
        asm volatile("nop");
    }
}

/* Main function */
int main(void) {
    unsigned int pattern = 0;
    unsigned int counter = 0;

    /* Test pattern in SRAM to verify writes */
    volatile unsigned int *test_addr = (volatile unsigned int *)0x00004000;

    while (1) {
        /* Write counter to SRAM */
        *test_addr = counter;

        /* LED pattern based on counter */
        if (pattern == 0) {
            *LED_BASE = LED1;          /* LED1 on, LED2 off */
            pattern = 1;
        } else if (pattern == 1) {
            *LED_BASE = LED2;          /* LED1 off, LED2 on */
            pattern = 2;
        } else if (pattern == 2) {
            *LED_BASE = LED1 | LED2;   /* Both LEDs on */
            pattern = 3;
        } else {
            *LED_BASE = 0;             /* Both LEDs off */
            pattern = 0;
        }

        /* Increment counter */
        counter++;

        /* Delay */
        delay(50000);
    }

    /* Never returns */
    return 0;
}
