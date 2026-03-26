#![no_std]
#![no_main]

use core::panic::PanicInfo;
use core::ptr::write_volatile;

const GPIO_ADDR: *mut u32 = 0x4000_0000 as *mut u32;
const UART_ADDR: *mut u32 = 0x4000_0004 as *mut u32;

fn write_uart(byte: u8) {
    unsafe {
        write_volatile(UART_ADDR, byte as u32);
    }
}

fn print(s: &str) {
    for byte in s.bytes() {
        write_uart(byte);
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    loop {
        print("Hello, World!\n");
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo<'_>) -> ! {
    loop {}
}
