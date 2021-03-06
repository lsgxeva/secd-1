; vim: filetype=nasm
; ==============================================================================
; Data cell type flags
;
; See secd.asm for details on data cell format and flags.
; ==============================================================================
;
%define SECD_TYPEMASK   0x77
%define SECD_CONS       0x00
%define SECD_ATOM       0x01
%define SECD_SYMBOL     0x00 | SECD_ATOM
%define SECD_NUMBER     0x02 | SECD_ATOM
%define SECD_BOOLEAN    0x04 | SECD_ATOM
%define SECD_RECIPE     0x08
%define SECD_HEAP       0x10
%define SECD_VECTOR     0x20 | SECD_HEAP | SECD_ATOM
%define SECD_BINARY     0x40 | SECD_HEAP | SECD_ATOM
