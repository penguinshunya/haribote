extern {
    fn io_load_eflags() -> u32;
    fn io_store_eflags(eflags: u32);
    fn load_cr0() -> u32;
    fn store_cr0(cr0: u32);
}

const EFLAGS_AC_BIT: u32 = 0x00040000;
const CR0_CACHE_DISABLE:u32 = 0x60000000;

pub unsafe fn test(start: u32, end: u32) -> u32 {
    let mut flg486 = false;
    let mut eflg: u32;
    let mut cr0: u32;

    eflg = io_load_eflags();
    eflg |= EFLAGS_AC_BIT;	/* AC-bit = 1 */
    io_store_eflags(eflg);
    eflg = io_load_eflags();
    if (eflg & EFLAGS_AC_BIT) != 0 {	/* 386ではAC=1にしても自動で0に戻ってしまう */
        flg486 = true;
    }
    eflg &= !EFLAGS_AC_BIT;	/* AC-bit = 0 */
    io_store_eflags(eflg);

    if !flg486 {
        cr0 = load_cr0();
        cr0 |= CR0_CACHE_DISABLE;	/* キャッシュ禁止 */
        store_cr0(cr0);
    }

    // i = memtest_sub(start, end);

    if !flg486 {
        cr0 = load_cr0();
        cr0 &= !CR0_CACHE_DISABLE;	/* キャッシュ許可 */
        store_cr0(cr0);
    }

    0
}
