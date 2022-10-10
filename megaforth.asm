include "Megaprocessor_defs.asm";

RETURN_STACK        equ 0x6000;

        org     0x400;
        dw      dup; //fn3,fn2;

        org     0;
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

        ld.w    r3,#0x400;
        jmp     _next;

_next:
        ld.w    r0,(r3++);
        move    r2,r0;
        ld.w    r0,(r2);
        jmp     (r0);

_docol:
        move    r0,r3;
        move    r3,r2;
        addq    r1,#-2;
        move    r2,r1;
        st.w    (r2),r0;
        addq    r3,#2;
        jmp     _next;

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

dup:
        dw      dup_inner;
dup_inner:
        ld.w    r0,(sp+0);
        push    r0;
        jmp     _next;

plus:
        dw      plus_inner;
plus_inner:
        pop     r0;
        pop     r1;
        add     r0,r1;
        push    r0;
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
