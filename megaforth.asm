include "Megaprocessor_defs.asm";

RETURN_STACK        equ 0x5FFE;

        org     0x3FFE;

ccw:
        dw;

        org     0x400;

        dw      fn3,fn2;

        org     0;


        // set up data stack
        ld.w    r0,#EXT_RAM_END;
        move    sp,r0;
        // set up return stack
        ld.w    r1,#RETURN_STACK;

        ld.w    r3,#0x400;

        jmp     _next;
_next:
        ld.w    r0,(r3++);
        move    r2,r0;
        ld.w    r0,(r2);
        jmp     (r0);
_docol:
        st.w    ccw,r2;
        move    r2,r1;
        move    r1,r3;
        st.w    (r2),r1;
        move    r1,r2;
        addq    r1,#-2;
        ld.w    r0,ccw;
        addq    r0,#2;
        move    r3,r0;
        jmp     _next;

exit:
        dw      exit_inner;
exit_inner:
        addq    r1,#2;
        move    r2,r1;
        ld.w    r0,(r2);
        move    r3,r0;
        jmp     _next;
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
