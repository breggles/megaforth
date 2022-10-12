include "Megaprocessor_defs.asm";

RETURN_STACK        equ 0x6000;

        org     0x400;
        dw      word,key,latest,fetch,lit,0x400,fetch,lit,0x1111,lit,0x2222,plus,lit,0x4321,branch,4;

        org     0;

        jmp     _start;

// NB: We're using r1 as the return stack pointer and r3 as the "instruction" pointer.
//     They can be used in words, but their values need to be stored and and restored,
//     before calling _next.

_docol:
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

r1_store:
        dw;
r3_store:
        dw;

// Primitives

exit_name:
        dw      0;
        db      5;
        dm      "exit";
exit:
        dw      exit_code;
exit_code:
        move    r2,r1;
        ld.w    r0,(r2);
        addq    r1,#2;
        move    r3,r0;
        jmp     _next;

drop_name:
        dw      exit_name;
        db      5;
        dm      "drop";
drop:
        dw      drop_code;
drop_code:
        pop     r0;
        jmp     _next;

swap_name:
        dw      drop_name;
        db      5;
        dm      "swap";
swap:
        dw      swap_code;
swap_code:
        pop     r0;
        pop     r2;
        push    r0;
        push    r2;
        jmp     _next;

dup_name:
        dw      swap_name;
        db      4;
        dm      "dup";
        db      0;
dup:
        dw      dup_code;
dup_code:
        ld.w    r0,(sp+0);
        push    r0;
        jmp     _next;

over_name:
        dw      dup_name;
        db      5;
        dm      "over";
over:
        dw      over_code;
over_code:
        ld.w    r0,(sp+2);
        push    r0;
        jmp     _next;

rot_name:
        dw      over_name;
        db      4;
        dm      "rot";
        db      0;
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

rotr_name:
        dw      rot_name;
        db      5;
        dm      "rot-";
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

drop2_name:
        dw      rotr_name;
        db      6;
        dm      "2drop";
        db      0;
drop2:
        dw      drop2_code;
drop2_code:
        pop     r0;
        pop     r0;
        jmp     _next;

dup2_name:
        dw      drop2_name;
        db      5;
        dm      "2dup";
dup2:
        dw      dup2_code;
dup2_code:
        ld.w    r0,(sp+0);
        ld.w    r2,(sp+2);
        jmp     _next;

swap2_name:
        dw      dup2_name;
        db      6;
        dm      "2swap";
        db      0;
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

branch_name:
        dw      swap2_name;
        db      7;
        dm      "branch";
branch:
        dw      branch_code;
branch_code:
        ld.w    r0,(r3);
        add     r3,r0;      // add 2 more?
        jmp     _next;

plus_name:
        dw      branch_name;
        db      5;
        dm      "plus";
plus:
        dw      plus_code;
plus_code:
        pop     r0;
        pop     r1;
        add     r0,r1;
        push    r0;
        jmp     _next;

lit_name:
        dw      plus_name;
        db      4;
        dm      "lit";
        db      0;
lit:
        dw      lit_code;
lit_code:
        ld.w    r0,(r3);
        push    r0;
        addq    r3,#2;
        jmp     _next;

fetch_name:
        dw      lit_name;
        db      2;
        dm      "@";
        db      0;
fetch:
        dw      fetch_code;
fetch_code:
        pop     r2;
        ld.w    r0,(r2);
        push    r0;
        jmp     _next;

key_name:
        dw      fetch_name;
        db      4;
        dm      "key";
        db      0;
key:
        dw      key_code;
key_code:
        jsr     _key;
        push    r0;
        jmp     _next;
_key:
        ld.w    r2,(currkey);
        ld.b    r0,(r2);
        // TODO: if r0 = 0, halt
        addq    r2,#1;
        st.w    currkey,r2;
        ret;
currkey:
        dw      buffer;

word_name:
        dw      key_name;
        db      5;
        dm      "word";
word:
        dw      word_code;
word_code:
        jsr     _key;
        ld.w    r2,#0x20; // Space
        cmp     r0,r2;
        beq     word_code;
        st.w    r3_store,r3;
        ld.w    r3,#word_buffer;
word_1:
        st.b    (r3++),r0;
        jsr     _key;
        ld.w    r2,#0x20; // Space
        cmp     r0,r2;
        bne     word_1;
        ld.w    r0,#word_buffer;
        push    r0;
        sub     r3,r0;
        push    r3;
        ld.w    r3,r3_store;
        jmp     _next;
word_buffer:
        ds      32;

// Variables

latest_name:
        dw      word_name;
        db      7;
        dm      "latest";
latest:
        dw      latest_code;
latest_code:
        ld.w    r0,#latest_var;
        push    r0;
        jmp     _next;
latest_var:
        dw      double_name;

// Words

double_name:
        dw      fetch_name;
        db      7;
        dm      "double";
double:
        dw      _docol,dup,plus,exit;

_start:
        // set up data stack
        ld.w    r0,#EXT_RAM_LEN;
        move    sp,r0;

        // set up return stack
        ld.w    r1,#RETURN_STACK;

        ld.w    r3,#0x400;
        jmp     _next;

buffer:
        dm      "lit 2 lit 3 +";
