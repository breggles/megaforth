include "Megaprocessor_defs.asm";

RETURN_STACK        equ 0x6000;

        org     0x400;
        dw      rot; //fn3,fn2;

        org     0;

        jmp     _init;

// NB: We're using r1 as the return stack pointer and r3 as the "instruction" pointer.
//     They can be used in words, but their values need to be stored and and restored,
//     before called _next.

_docol:                     // Has address 3, i.e. codeword 3 means it's not primitive
        move    r0,r3;
        move    r3,r2;
        addq    r1,#-2;
        move    r2,r1;
        st.w    (r2),r0;
        addq    r3,#2;
        jmp     _next;

_next:
        ld.w    r0,(r3++);
        move    r2,r0;
        ld.w    r0,(r2);
        jmp     (r0);

exit:
        dw      exit_inner;
exit_inner:
        move    r2,r1;
        ld.w    r0,(r2);
        addq    r1,#2;
        move    r3,r0;
        jmp     _next;

drop:
        dw      drop_inner;
drop_inner:
        pop     r0;
        jmp     _next;

swap:
        dw      swap_inner;
swap_inner:
        pop     r0;
        pop     r2;
        push    r0;
        push    r2;
        jmp     _next;

dup:
        dw      dup_inner;
dup_inner:
        ld.w    r0,(sp+0);
        push    r0;
        jmp     _next;

over:
        dw      over_inner;
over_inner:
        ld.w    r0,(sp+2);
        push    r0;
        jmp     _next;

rot:
        dw      rot_inner;
rot_inner:
        st.w    r1_store,r1;
        pop     r0;
        pop     r1;
        pop     r2;
        push    r0;
        push    r2;
        push    r1;
        ld.w    r1,r1_store;
        jmp     _next;
plus:
        dw      plus_inner;
plus_inner:
        pop     r0;
        pop     r1;
        add     r0,r1;
        push    r0;
        jmp     _next;

double:
        dw      _docol,dup,plus,exit;

r1_store:
        dw;

r3_store:
        dw;

fn1:
        dw      f1_inner;
f1_inner:
        ld.b    r0,#0x11;
        jmp     _next;

fn2:
        dw      fn2_inner;
fn2_inner:
        ld.b    r0,#0x22;
        jmp     _next;

fn3:
        dw      _docol,fn1,exit;

_init:
        // set up data stack
        ld.w    r0,#EXT_RAM_LEN;
        move    sp,r0;
        // set up return stack
        ld.w    r1,#RETURN_STACK;

        // put some data on data stack for testing
        ld.w    r0,#0x1;
        push    r0;
        ld.w    r0,#0x1234;
        push    r0;
        ld.w    r0,#0x2345;
        push    r0;
        ld.w    r0,#0x3456;
        push    r0;

        ld.w    r3,#0x400;
        jmp     _next;
