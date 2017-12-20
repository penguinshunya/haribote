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

extern "C" {
    fn tsprintf(buff: *mut u8, fmt: *const u8, ...);
    fn putfonts8_asc(vram: *mut u8, xsize: u32, x: u32, y: u32, c: u8, s: *const u8);
}

#[no_mangle]
pub unsafe fn hari_main() {
    let binfo = 0x00000ff0 as *const BOOTINFO;

    let memtotal = memory::test(0x00400000, 0xbfffffff);

    graphic::init_palette();
    graphic::init_screen((*binfo).vram, (*binfo).scrnx as u32, (*binfo).scrny as u32);

    let s: &[u8] = &[0; 256];
    tsprintf(s.as_ptr() as *mut u8, b"abc%010d\0".as_ptr(), 100);
    putfonts8_asc((*binfo).vram, (*binfo).scrnx as u32, 0, 0, 0, s.as_ptr());

    loop {
        asm!("hlt");
    }
}

#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] fn panic_fmt() -> ! { loop {} }
