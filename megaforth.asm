include "Megaprocessor_defs.asm";

RETURN_STACK        equ 0x6000;

        org     0x3FFE;

current_code_word:
        dw;

        org     0x400;

        dw      plus; //fn3,fn2;

        org     0;

        // set up data stack
        ld.w    r0,#EXT_RAM_LEN;
        move    sp,r0;
        // set up return stack
        ld.w    r1,#RETURN_STACK;

        ld.w    r3,#0x400;

        ld.w    r0,#0x1234;
        push    r0;
        ld.w    r0,#0x1;
        push    r0;


        jmp     _next;

_next:
        ld.w    r0,(r3++);
        move    r2,r0;
        ld.w    r0,(r2);
        jmp     (r0);

_docol:
        st.w    current_code_word,r2;
        move    r2,r1;
        move    r1,r3;
        addq    r2,#-2;
        st.w    (r2),r1;
        move    r1,r2;
        ld.w    r3,current_code_word;
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
