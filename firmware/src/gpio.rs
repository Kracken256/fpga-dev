use core::ptr::write_volatile;

const GPIO_ADDR: *mut u32 = 0x4000_0000 as *mut u32;

#[inline(always)]
pub fn write(value: u32) {
    unsafe {
        write_volatile(GPIO_ADDR, value);
    }
}
