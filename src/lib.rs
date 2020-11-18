#![feature(lang_items)]
#![no_std]

use core::panic::PanicInfo;

mod vga_buffer;

#[no_mangle]
pub extern fn rust_main() {
	vga_buffer::print_something();

    // ATTENTION: we have a very small stack and no guard page

    let hello = b"Hello World!";
    let color_byte = 0x1f; // white foreground, blue background

    let mut hello_colored = [color_byte; 24];
    for (i, char_byte) in hello.into_iter().enumerate() {
        hello_colored[i*2] = *char_byte;
    }

    // write `Hello World!` to the center of the VGA text buffer
    let buffer_ptr = (0xb8000 + 1988) as *mut _;
    unsafe { *buffer_ptr = hello_colored };

    loop{}
}

pub fn print_something() {

}

#[lang = "eh_personality"]
#[no_mangle]
extern "C" fn rust_eh_personality() {

}

#[panic_handler]
#[no_mangle]
extern "C" fn panic_handler(_info: &PanicInfo) -> ! {
	loop { }
}
