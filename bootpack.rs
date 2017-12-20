#![feature(lang_items)]
#![no_std]
#![feature(asm)]

mod graphic;
mod memory;

#[repr(C, packed)]
struct BOOTINFO {
    cyls: u8, leds: u8, vmode: u8, reserve: u8,
    scrnx: u16, scrny: u16,
    vram: *mut u8,
}

#[no_mangle]
pub unsafe fn hari_main() {
    let binfo = 0x00000ff0 as *const BOOTINFO;

    let memtotal = memory::test(0x00400000, 0xbfffffff);

    graphic::init_palette();
    graphic::init_screen((*binfo).vram, (*binfo).scrnx as u32, (*binfo).scrny as u32);

    loop {
        asm!("hlt");
    }
}

#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] fn panic_fmt() -> ! { loop {} }
