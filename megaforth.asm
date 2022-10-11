include "Megaprocessor_defs.asm";

RETURN_STACK        equ 0x6000;

        org     0x400;
        dw      lit,0x400,fetch,lit,0x1111,lit,0x2222,plus,lit,0x4321,branch,4,fn1,fn2; //fn3,fn2;

        org     0;

        jmp     _start;

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
        dw      exit_code;
exit_code:
        move    r2,r1;
        ld.w    r0,(r2);
        addq    r1,#2;
        move    r3,r0;
        jmp     _next;

drop:
        dw      drop_code;
drop_code:
        pop     r0;
        jmp     _next;

swap:
        dw      swap_code;
swap_code:
        pop     r0;
        pop     r2;
        push    r0;
        push    r2;
        jmp     _next;

dup:
        dw      dup_code;
dup_code:
        ld.w    r0,(sp+0);
        push    r0;
        jmp     _next;

over:
        dw      over_code;
over_code:
        ld.w    r0,(sp+2);
        push    r0;
        jmp     _next;

rot:
        dw      rot_code;
rot_code:
        st.w    r1_store,r1;
        pop     r0;
        pop     r1;
        pop     r2;
        push    r1;
        push    r0;
        push    r2;
        ld.w    r1,r1_store;
        jmp     _next;

rotr:
        dw      rotr_code;
rotr_code:
        st.w    r1_store,r1;
        pop     r0;
        pop     r1;
        pop     r2;
        push    r0;
        push    r2;
        push    r1;
        ld.w    r1,r1_store;
        jmp     _next;

drop2:
        dw      drop2_code;
drop2_code:
        pop     r0;
        pop     r0;
        jmp     _next;

dup2:
        dw      dup2_code;
dup2_code:
        ld.w    r0,(sp+0);
        ld.w    r2,(sp+2);
        jmp     _next;

swap2:
        dw      swap2_code;
swap2_code:
        st.w    r1_store,r1;
        st.w    r3_store,r3;
        pop     r0;
        pop     r1;
        pop     r2;
        pop     r3;
        push    r1;
        push    r0;
        push    r3;
        push    r2;
        ld.w    r1,r1_store;
        ld.w    r3,r3_store;
        jmp     _next;

branch:
        dw      branch_code;
branch_code:
        ld.w    r0,(r3);
        add     r3,r0;      // add 2 more?
        jmp     _next;

plus:
        dw      plus_code;
plus_code:
        pop     r0;
        pop     r1;
        add     r0,r1;
        push    r0;
        jmp     _next;

lit:
        dw      lit_code;
lit_code:
        ld.w    r0,(r3);
        push    r0;
        addq    r3,#2;
        jmp     _next;

fetch:
        dw      fetch_code;
fetch_code:
        pop     r2;
        ld.w    r0,(r2);
        push    r0;
        jmp     _next;

double:
        dw      _docol,dup,plus,exit;

fn1:
        dw      f1_code;
f1_code:
        ld.b    r0,#0x11;
        jmp     _next;

fn2:
        dw      fn2_code;
fn2_code:
        ld.b    r0,#0x22;
        jmp     _next;

fn3:
        dw      _docol,fn1,exit;

_start:
        // set up data stack
        ld.w    r0,#EXT_RAM_LEN;
        move    sp,r0;

        // set up return stack
        ld.w    r1,#RETURN_STACK;

        ld.w    r3,#0x400;
        jmp     _next;

r1_store:
        dw;

r3_store:
        dw;
