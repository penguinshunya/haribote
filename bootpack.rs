#![feature(lang_items)]
#![no_std]
#![feature(asm)]

extern {
    fn io_cli();
    fn io_out8(port: u32, data: u32);
    fn io_load_eflags() -> u32;
    fn io_store_eflags(eflags: u32);
}

#[repr(C, packed)]
struct BOOTINFO {
    cyls: u8, leds: u8, vmode: u8, reserve: u8,
    scrnx: u16, scrny: u16,
    vram: *mut u8,
}

#[no_mangle]
pub unsafe fn hari_main() {
    let binfo = 0x00000ff0 as *const BOOTINFO;

    init_palette();
    init_screen((*binfo).vram, (*binfo).scrnx as u32, (*binfo).scrny as u32);

    loop {
        asm!("hlt");
    }
}

const TABLE_RGB: [u32; 48] = [
	0x00, 0x00, 0x00,
	0xff, 0x00, 0x00,
	0x00, 0xff, 0x00,
	0xff, 0xff, 0x00,
	0x00, 0x00, 0xff,
	0xff, 0x00, 0xff,
	0x00, 0xff, 0xff,
	0xff, 0xff, 0xff,
	0xc6, 0xc6, 0xc6,
	0x84, 0x00, 0x00,
	0x00, 0x84, 0x00,
	0x84, 0x84, 0x00,
	0x00, 0x00, 0x84,
	0x84, 0x00, 0x84,
	0x44, 0x88, 0xcc,
	0x84, 0x84, 0x84,
];

unsafe fn init_palette() {
	set_palette(&TABLE_RGB);
}

unsafe fn set_palette(rgb: &[u32; 48]) {
    let eflags = io_load_eflags();
    io_cli();
    io_out8(0x03c8, 0);
    for i in 0..48 {
        io_out8(0x03c9, rgb[i]);
    }
    io_store_eflags(eflags);
}

pub const COL8_000000: u8 = 0;
pub const COL8_FF0000: u8 = 1;
pub const COL8_00FF00: u8 = 2;
pub const COL8_FFFF00: u8 = 3;
pub const COL8_0000FF: u8 = 4;
pub const COL8_FF00FF: u8 = 5;
pub const COL8_00FFFF: u8 = 6;
pub const COL8_FFFFFF: u8 = 7;
pub const COL8_C6C6C6: u8 = 8;
pub const COL8_840000: u8 = 9;
pub const COL8_008400: u8 = 10;
pub const COL8_848400: u8 = 11;
pub const COL8_000084: u8 = 12;
pub const COL8_840084: u8 = 13;
pub const COL8_4488CC: u8 = 14;
pub const COL8_848484: u8 = 15;

unsafe fn init_screen(vram: *mut u8, xsize: u32, ysize: u32) {
    // boxfill8(vram, xsize, COL8_4488CC,          0,          0, xsize -  1, ysize - 29);
    // boxfill8(vram, xsize, COL8_C6C6C6,          0, ysize - 28, xsize -  1, ysize - 28);
    // boxfill8(vram, xsize, COL8_FFFFFF,          0, ysize - 27, xsize -  1, ysize - 27);
    // boxfill8(vram, xsize, COL8_C6C6C6,          0, ysize - 26, xsize -  1, ysize -  1);

    boxfill8(vram, xsize, COL8_FFFFFF,          3, ysize - 24,         59, ysize - 24);
    boxfill8(vram, xsize, COL8_FFFFFF,          2, ysize - 24,          2, ysize -  4);
    boxfill8(vram, xsize, COL8_848484,          3, ysize -  4,         59, ysize -  4);
    boxfill8(vram, xsize, COL8_848484,         59, ysize - 23,         59, ysize -  5);
    boxfill8(vram, xsize, COL8_000000,          2, ysize -  3,         59, ysize -  3);
    boxfill8(vram, xsize, COL8_000000,         60, ysize - 24,         60, ysize -  3);

    boxfill8(vram, xsize, COL8_848484, xsize - 47, ysize - 24, xsize -  4, ysize - 24);
    boxfill8(vram, xsize, COL8_848484, xsize - 47, ysize - 23, xsize - 47, ysize -  4);
    boxfill8(vram, xsize, COL8_FFFFFF, xsize - 47, ysize -  3, xsize -  4, ysize -  3);
    boxfill8(vram, xsize, COL8_FFFFFF, xsize -  3, ysize - 24, xsize -  3, ysize -  3);
}

unsafe fn boxfill8(vram: *mut u8, xsize: u32, c: u8, x0: u32, y0: u32, x1: u32, y1: u32)
{
    for y in y0..(y1 + 1) {
        for x in x0..(x1 + 1) {
            *vram.offset((y * xsize + x) as isize) = c;
        }
    }
}

#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] fn panic_fmt() -> ! { loop {} }
