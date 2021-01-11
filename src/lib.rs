#![feature(abi_x86_interrupt)]
#![feature(lang_items)]
#![no_std]

use core::panic::PanicInfo;

mod gdt;
mod interrupts;
mod vga_buffer;

#[no_mangle]
pub extern "C" fn rust_main() {
    init();

    use x86_64::registers::control::Cr3;

    let (level_4_page_table, _) = Cr3::read();
    println!(
        "Level 4 page table at: {:?}",
        level_4_page_table.start_address()
    );

    hlt_loop();
}

fn init() {
    interrupts::init_idt();
    gdt::init();
    unsafe { interrupts::PICS.lock().initialize() };
    x86_64::instructions::interrupts::enable();
}

fn hlt_loop() -> ! {
    loop {
        x86_64::instructions::hlt();
    }
}

#[lang = "eh_personality"]
#[no_mangle]
extern "C" fn rust_eh_personality() {}

#[panic_handler]
#[no_mangle]
extern "C" fn panic_handler(info: &PanicInfo) -> ! {
    println!("{}", info);
    hlt_loop()
}
