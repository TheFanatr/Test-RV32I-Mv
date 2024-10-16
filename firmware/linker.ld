ENTRY(_start)
phys = 0;

MEMORY
{
  RAM (rwx) : ORIGIN = 0, LENGTH = 64K
}

SECTIONS
{

  .entry :
  {
    . = ALIGN(4);  
    . = 0;
    KEEP(*(.entry))
  } > RAM

  .text :
  {
    . = ALIGN(4);  
    *(.text .text.*)
  } > RAM

  .data :
  {
    *(.data .data*)
  } > RAM

  .rodata :
  {
    . = ALIGN(4);  
    *(.rodata .rodata.*)
  } > RAM

  .exit :
  {
    . = ALIGN(4);
    KEEP(*(.exit))
  } > RAM

}
