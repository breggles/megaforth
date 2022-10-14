include "Megaprocessor_defs.asm";

RETURN_STACK        equ 0x6000;     // totally made up number, feel free to change

        org     0x400;
        dw      lit,buffer,lit,0x4,find,tcfa,lit,buffer,lit,0x2,number,word,key,latest,fetch,lit,0x400,fetch,lit,0x1111,lit,0x2222,plus,lit,0x4321,branch,4;

        org     0;

        jmp     _start;

// NB: We're using r1 as the return stack pointer and r3 as the "instruction" pointer.
//     They can be used in code, but their values need to be stored and restored,
//     before calling _next.
//
//     Update: I might revise this and store them in memory, somewhere...

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
        db      4;
        dm      "exit";
exit:
        dw      $+2;
        move    r2,r1;
        ld.w    r0,(r2);
        addq    r1,#2;
        move    r3,r0;
        jmp     _next;

drop_name:
        dw      exit_name;
        db      4;
        dm      "drop";
drop:
        dw      $+2;
        pop     r0;
        jmp     _next;

swap_name:
        dw      drop_name;
        db      4;
        dm      "swap";
swap:
        dw      $+2;
        pop     r0;
        pop     r2;
        push    r0;
        push    r2;
        jmp     _next;

dup_name:
        dw      swap_name;
        db      3;
        dm      "dup";
dup:
        dw      $+2;
        ld.w    r0,(sp+0);
        push    r0;
        jmp     _next;

over_name:
        dw      dup_name;
        db      4;
        dm      "over";
over:
        dw      $+2;
        ld.w    r0,(sp+2);
        push    r0;
        jmp     _next;

rot_name:
        dw      over_name;
        db      3;
        dm      "rot";
rot:
        dw      $+2;
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
        db      4;
        dm      "rot-";
rotr:
        dw      $+2;
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
        db      5;
        dm      "2drop";
drop2:
        dw      $+2;
        pop     r0;
        pop     r0;
        jmp     _next;

dup2_name:
        dw      drop2_name;
        db      4;
        dm      "2dup";
dup2:
        dw      $+2;
        ld.w    r0,(sp+0);
        ld.w    r2,(sp+2);
        jmp     _next;

swap2_name:
        dw      dup2_name;
        db      5;
        dm      "2swap";
swap2:
        dw      $+2;
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
        db      6;
        dm      "branch";
branch:
        dw      $+2;
        ld.w    r0,(r3);
        add     r3,r0;      // add 2 more?
        jmp     _next;

plus_name:
        dw      branch_name;
        db      4;
        dm      "plus";
plus:
        dw      $+2;
        pop     r0;
        pop     r1;
        add     r0,r1;
        push    r0;
        jmp     _next;

lit_name:
        dw      plus_name;
        db      3;
        dm      "lit";
lit:
        dw      $+2;
        ld.w    r0,(r3);
        push    r0;
        addq    r3,#2;
        jmp     _next;

fetch_name:
        dw      lit_name;
        db      1;
        dm      "@";
fetch:
        dw      $+2;
        pop     r2;
        ld.w    r0,(r2);
        push    r0;
        jmp     _next;

key_name:
        dw      fetch_name;
        db      3;
        dm      "key";
key:
        dw      $+2;
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
        db      4;
        dm      "word";
word:
        dw      $+2;
word_2:
        jsr     _key;
        ld.w    r2,#0x20; // Space
        cmp     r0,r2;
        beq     word_2;
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

number_name:
        dw      word_name;
        db      6;
        dm      "number";
number:
        //TODO: do bases > 10
        //TODO: do negative numbers
        //TODO: error handling
        dw      $+2;
        st.w    r1_store,r1;
        st.w    r3_store,r3;
        clr     r3;
number_2:
        ld.w    r0,(sp+0);     //string length
        test    r0;
        beq     number_1;
        move    r0,r3;
        ld.b    r1,base_var;
        mulu;
        move    r3,r2;
        ld.w    r0,(sp+0);     //string length
        ld.w    r2,(sp+2);     //start address of string
        addq    r0,#-1;
        st.w    (sp+0),r0;
        ld.w    r0,#0x30;
        ld.b    r1,(r2);
        sub     r1,r0;
        add     r3,r1;
        addq    r2,#1;
        st.w    (sp+2),r2;
        jmp     number_2;
number_1:
        st.w    (sp+2),r3;
        ld.w    r1,r1_store;
        ld.w    r3,r3_store;
        jmp     _next;

find_name:
        //TODO: implement HIDDEN
        dw      number_name;
        db      4;
        dm      "find";
find:
        dw      $+2;
        st.w    r1_store,r1;
        st.w    r3_store,r3;
        clr     r0;
        push    r0;                 // word end
        ld.w    r2,latest_var;
        push    r2;                 // addr of prev
find_loop:
        beq     find_not_found;
        ld.w    r0,(sp+4);          // string length
        addq    r2,#2;              // addr word length
        ld.b    r1,(r2++);          // word length
        cmp     r0,r1;              // cmp lengths
        bne     find_prev;
        add     r1,r2;
        st.w    (sp+2),r1;
        ld.w    r3,(sp+6);          // addr string
find_cmp_str:                       // move to sub routine?
        ld.b    r0,(r3++);
        ld.b    r1,(r2++);
        cmp     r0,r1;              // cmp chars
        bne     find_prev;
        ld.w    r1,(sp+2);
        cmp     r2,r1;
        bne     find_cmp_str;       // string done
find_not_found:
        pop     r2;
        pop     r0;
        pop     r0;
        st.w    (sp+0),r2;
        ld.w    r1,r1_store;
        ld.w    r3,r3_store;
        jmp     _next;
find_prev:
        ld.w    r2,(sp+0);
        ld.w    r1,(r2);
        move    r2,r1;
        st.w    (sp+0),r2;
        jmp     find_loop;

tcfa_name:
        dw      find_name;
        db      4;
        dm      ">cfa";
tcfa:
        dw      $+2;
        pop     r2;
        addq    r2,#2;
        ld.b    r0,(r2);
        add     r2,r0;
        addq    r2,#2;          // zero-terminated plus one more
        push    r2;
        jmp     _next;

// Words

double_name:
        dw      tcfa_name;
        db      6;
        dm      "double";
double:
        dw      _docol,dup,plus,exit;

// Variables

base_name:
        dw      double_name;
        db      4;
        dm      "base";
base:
        dw      $+2;
        ld.w    r0,#base_var;
        push    r0;
        jmp     _next;
base_var:
        db      10;

latest_name:
        dw      base_name;
        db      6;
        dm      "latest";
latest:
        dw      $+2;
        ld.w    r0,#latest_var;
        push    r0;
        jmp     _next;
latest_var:
        dw      latest_name;

_start:
        // set up data stack
        ld.w    r0,#EXT_RAM_LEN;
        move    sp,r0;

        // set up return stack
        ld.w    r1,#RETURN_STACK;

        ld.w    r3,#0x400;
        jmp     _next;

buffer:
        dm      "2dup";
