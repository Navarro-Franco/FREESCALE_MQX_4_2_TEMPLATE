ENTRY(__boot)
EXTERN(main)

MEMORY
{   qspi_conf         (RX): ORIGIN = 0x20000000, LENGTH = 0x00000400
    boot_ivt          (RX): ORIGIN = 0x20000400, LENGTH = 0x00000020
    boot_data          (RX): ORIGIN = 0x20000420, LENGTH = 0x00000010
    boot_dcd          (RX): ORIGIN = 0x20000430, LENGTH = 0x000003CC
    text            (RX): ORIGIN = 0x20000800, LENGTH = 0x0002F7F0
    data            (RW): ORIGIN = 0x3f070000, LENGTH = 0x0000EBB0
    reserved        (RWX): ORIGIN = 0x3f07ebf0, LENGTH = 0x00000400
}

CODE_BASE_ADDR_START            = ORIGIN(text);
CODE_SIZE                       = LENGTH(text);
CODE_BASE_ADDR_END              = CODE_BASE_ADDR_START + CODE_SIZE;

DATA_BASE_ADDR_START            = ORIGIN(data);
DATA_SIZE                       = LENGTH(data);
DATA_BASE_ADDR_END              = DATA_BASE_ADDR_START + DATA_SIZE;


/* exported symbols */
__DEFAULT_PROCESSOR_NUMBER      = 1;
__DEFAULT_INTERRUPT_STACK_SIZE  = 0x800;


/* 64kB of  shared memory */
__SHARED_RAM_START              = 0x3f040000;
__SHARED_RAM_END                = 0x3f04fff0;
__SRAM_POOL_START               = DATA_BASE_ADDR_START;
__SRAM_POOL_END                 = DATA_BASE_ADDR_END;
__UNCACHED_DATA_START           = DATA_BASE_ADDR_START;
__UNCACHED_DATA_END             = DATA_BASE_ADDR_END;
__BOOT_STACK_SIZE               = 0x100;
__BOOT_STACK_ADDRESS            = DATA_BASE_ADDR_END - __BOOT_STACK_SIZE;
__KERNEL_DATA_END               = DATA_BASE_ADDR_END;

__FIQ_STACK_SIZE = 0;
__ABT_STACK_SIZE = 0;
__UND_STACK_SIZE = 0;
__SYS_STACK_SIZE = 0;

SECTIONS
{   
    .qspi_conf : 
    {
        KEEP(*(.conf))
    } > qspi_conf
    
    .boot_ivt : 
    {
        KEEP(*(.ivt))
    } > boot_ivt
    
    .boot_data : 
    {
        KEEP(*(.boot_data))
    } > boot_data

    .boot_dcd : 
    {
        KEEP(*(.dcd))
    } > boot_dcd
    
    /* place text */
    .text :
    {
        *("STARTUP")
        *(KERNEL)
        *(.text*)
        *(.rodata*)
        
        /* glue arm/thumb and thumb/arm code */
        *(.glue_7)
        *(.glue_7t)
        
        /* unwind exception frame */
        KEEP(*(.eh_frame))
        KEEP(*(.eh_frame_hdr))
        
        . = ALIGN(0x8);
        KEEP (*crtbegin.o(.ctors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
        KEEP (*(SORT(.ctors.*)))
        KEEP (*crtend.o(.ctors))
        
        KEEP (*crtbegin.o(.dtors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
        KEEP (*(SORT(.dtors.*)))
        KEEP (*crtend.o(.dtors))
        
        /* preinit_array */
        __preinit_array_start = .;
        KEEP (*(.preinit_array*))
        __preinit_array_end = .;
        
        /* init_array */
        __init_array_start = .;
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array*))
        __init_array_end = .;
        
        /* fini_array */
        __fini_array_start = .;
        KEEP (*(SORT(.fini_array.*)))
        KEEP (*(.fini_array*))
        __fini_array_end = .;
        
        /* codesourcery init table */
        __cs3_regions = .;
        LONG(0)
        LONG(LOADADDR(.data))
        LONG(_data_start)
        LONG(_data_end - _data_start)
        LONG(_bss_end - _bss_start)
        
        /* perform copy of reserved sections */
        LONG(0)
        LONG(LOADADDR(.reserved))
        LONG(_reserved_start)
        LONG(_reserved_end - _reserved_start)
        LONG(0)
        
        __cs3_regions_end = .;
        . = ALIGN (8);
    } > text
    
    /* number of region, keep outside any section */
    __cs3_region_num = 2;
    /* don't use codesourcery heap */
    __cs3_heap_start = 0;
    
    /* unwind exception frame */
    .ARM.extab :
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > text
    .ARM :
    {
        __exidx_start = .;
        *(.ARM.exidx*)
        __exidx_end = .;
    } > text
    
    /* place data, region address must be 8B aligned */
    .data :
    {
        _data_start = .;
        *(.data*)
        . = ALIGN(8);
        _data_end = .;
    } > data AT> text
    
    /* 
        .bss must be placed AFTER .data so normal initialization can be done in 1.st cs3 region, 
        base address, section size must be 8 aligned !
    */
    .bss BLOCK(8) :
    {
      _bss_start = .;
      *(.bss*)
      *(COMMON)
      . = ALIGN(8);
      _bss_end = .;
    } > data
    
   
    /* stacks */
    FIQ_STACK BLOCK(8) : 
    {
        _FIQ_STACK_START = .;
        . = . + __FIQ_STACK_SIZE;
        _FIQ_STACK_END = .;
    } > data
    ABT_STACK BLOCK(8) : 
    {
        _ABT_STACK_START = .;
        . = . + __ABT_STACK_SIZE;
        _ABT_STACK_END = .;
    } > data
    UND_STACK BLOCK(8) : 
    {
        _UND_STACK_START = .;
        . = . + __UND_STACK_SIZE;
        _UND_STACK_END = .;
    } > data
    SYS_STACK BLOCK(8) : 
    {
        _SYS_STACK_START = .;
        . = . + __SYS_STACK_SIZE;
        _SYS_STACK_END = .;
    } > data
    
    .kernel_data BLOCK(0x10) : 
    {
        __KERNEL_DATA_START = ALIGN(0x10);
    } > data
    
    .reserved : 
    {
        _reserved_start = .;
        *(.boot_reserved_data*)
        *(.boot_reserved_code*)
        . = ALIGN(8);
        _reserved_end = .;
    } > reserved AT> text
}

