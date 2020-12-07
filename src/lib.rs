#![feature(abi_x86_interrupt)]
#![feature(lang_items)]
#![no_std]

use core::panic::PanicInfo;

mod interrupts;
mod vga_buffer;

#[no_mangle]
pub extern "C" fn rust_main() {
    interrupts::init_idt();

    for i in 0..5 {
        println!(
            "i = {}, i * i = {}, i / 7.0 = {}",
            i,
            i * i,
            (i as f64) / 7.0
        );
    }

    println!("I'm really booted up and executing rust code!");

    x86_64::instructions::interrupts::int3();

    loop {}
}

#[lang = "eh_personality"]
#[no_mangle]
extern "C" fn rust_eh_personality() {}

#[panic_handler]
#[no_mangle]
extern "C" fn panic_handler(info: &PanicInfo) -> ! {
    println!("{}", info);
    loop {}
}
