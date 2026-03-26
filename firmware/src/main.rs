#![no_std]
#![no_main]

mod gpio;
mod uart;

use core::panic::PanicInfo;

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    loop {
        uart::write_str("Hello, World!\r\n");
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo<'_>) -> ! {
    loop {}
}
