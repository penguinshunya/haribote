#![feature(lang_items)]
#![no_std]
#![feature(asm)]

#[no_mangle]
pub fn hari_main() {
    loop {
        unsafe { asm!("hlt"); }
    }
}

#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] fn panic_fmt() -> ! { loop {} }
