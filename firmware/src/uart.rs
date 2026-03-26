use core::ptr::{read_volatile, write_volatile};

const UART_ADDR: *mut u32 = 0x4000_0004 as *mut u32;

#[inline(always)]
fn tx_ready() -> bool {
    unsafe { (read_volatile(UART_ADDR as *const u32) & 1) != 0 }
}

#[inline(always)]
pub fn write_byte(byte: u8) {
    while !tx_ready() {}
    unsafe {
        write_volatile(UART_ADDR, byte as u32);
    }
}

pub fn write_str(s: &str) {
    for b in s.bytes() {
        write_byte(b);
    }
}
