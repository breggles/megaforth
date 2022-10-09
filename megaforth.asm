include "Megaprocessor_defs.asm";

        org     0x400;

        dw      cw2,cw1;

        org     0;

        clr     r1;
        clr     r2;
        ld.w    r3,#0x400;
        jmp     _next;
_next:
        ld.w    r0,(r3);
        addq    r3,#2;
        move    r2,r0;
        ld.w    r0,(r2);
        jmp     (r0);
cw1:
        dw      fn1;
fn1:
        ld.b    r1,#0x11;
        jmp     _next;
cw2:
        dw      fn2;
fn2:
        ld.b    r1,#0x22;
        jmp     _next;
