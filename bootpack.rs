#![feature(lang_items)]
#![no_std]
#![feature(asm)]

extern {
    fn io_cli();
    fn io_out8(port: u32, data: u32);
    fn io_load_eflags() -> u32;
    fn io_store_eflags(eflags: u32);
}

#[no_mangle]
pub unsafe fn hari_main() {
    init_palette();

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
	set_palette(0, 15, &TABLE_RGB);
}

unsafe fn set_palette(start: u32, end: u32, rgb: &[u32; 48]) {
    let eflags = io_load_eflags();
    io_cli();
    io_out8(0x03c8, start);
    // for i in start..(end + 1) {
    //     let n = (i / 3 * 3 + i) as usize;
    //     io_out8(0x03c9, rgb[n]);
    //     io_out8(0x03c9, rgb[n + 1]);
    //     io_out8(0x03c9, rgb[n + 2]);
    // }
    io_store_eflags(eflags);
}

#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] fn panic_fmt() -> ! { loop {} }
