include "Megaprocessor_defs.asm";

RETURN_STACK        equ 0x6000;     // totally made up number, feel free to change

        org     0x2000;
        dw      quit,rz,rspstore; //,interpret,lit,buffer,lit,0x4,find,tdfa,lit,0x3,incr2,lit,buffer,lit,0x4,find,tcfa,lit,buffer,lit,0x2,number,word,key,latest,fetch,lit,0x400,fetch,lit,0x1111,lit,0x2222,plus,lit,0x4321,branch,4;

        org     0;

        jmp     _start;

// NB: We're using r1 as the return stack pointer and r3 as the "instruction" pointer.
//     They can be used in code, but their values need to be stored and restored,
//     before calling _next.
//
//     Update: I might revise this and store them in memory, somewhere...

        nop;
ext_int:
        reti;
        nop;
        nop;
        nop;
div_zero:
        reti;
        nop;
        nop;
        nop;
illegal:
        reti;
        nop;
        nop;
        nop;

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

nrot_name:
        dw      rot_name;
        db      4;
        dm      "rot-";
nrot:
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

twodrop_name:
        dw      nrot_name;
        db      5;
        dm      "2drop";
twodrop:
        dw      $+2;
        pop     r0;
        pop     r0;
        jmp     _next;

twodup_name:
        dw      twodrop_name;
        db      4;
        dm      "2dup";
twodup:
        dw      $+2;
        jsr     _twodup;
        jmp     _next;
_twodup:
        ld.w    r0,(sp+0);
        ld.w    r2,(sp+2);
        ret;

twoswap_name:
        dw      twodup_name;
        db      5;
        dm      "2swap";
twoswap:
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

incr2_name:
        dw      twoswap_name;
        db      6;
        dm      "incr2";
incr2:
        dw      $+2;
        pop     r0;
        addq    r0,#2;
        push    r0;
        jmp     _next;

branch_name:
        dw      incr2_name;
        db      6;
        dm      "branch";
branch:
        dw      $+2;
        ld.w    r0,(r3);
        add     r3,r0;      // add 2 more?
        jmp     _next;

plus_name:
        dw      branch_name;
        db      1;
        dm      "+";
plus:
        dw      $+2;
        pop     r0;
        pop     r2;
        add     r0,r2;
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

rspstore_name:
        dw      fetch_name;
        db      4;
        dm      "rsp!";
rspstore:
        dw      $+2;
        pop     r1;
        jmp     _next;

key_name:
        dw      rspstore_name;
        db      3;
        dm      "key";
key:
        dw      $+2;
        jsr     _key;
        push    r0;
        jmp     _next;
_key:
        ld.w    r2,(currkey);
        ld.b    r0,(r2++);
        // TODO: if key is 0, halt
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
        jsr     _word;
        push    r0;             // word ptr
        push    r2;             // word length
        jmp     _next;
_word:
        st.w    r1_store,r1;
        st.w    r3_store,r3;
word_2:
        jsr     _key;
        ld.w    r1,#0x20;       // Space
        cmp     r0,r1;
        beq     word_2;
        ld.w    r3,#word_buffer;
word_1:
        st.b    (r3++),r0;
        jsr     _key;
        ld.w    r1,#0x20;       // Space
        cmp     r0,r1;
        bne     word_1;
        ld.w    r0,#word_buffer;
        sub     r3,r0;
        move    r2,r3;
        ld.w    r3,r3_store;
        ld.w    r1,r1_store;
        ret;
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
        // Returns number of unparsed characters on top of stack followed by parsed number
        dw      $+2;
        jsr     _number;
        jmp     _next;
_number:
        st.w    r1_store,r1;
        st.w    r3_store,r3;
        clr     r3;
number_2:
        ld.w    r0,(sp+2);     //string length
        test    r0;
        beq     number_1;
        move    r0,r3;
        ld.b    r1,base_var;
        mulu;
        move    r3,r2;
        ld.w    r0,(sp+2);     //string length
        ld.w    r2,(sp+4);     //start address of string
        addq    r0,#-1;
        st.w    (sp+2),r0;
        ld.w    r0,#0x30;      // ascii code for 0
        ld.b    r1,(r2);
        sub     r1,r0;
        add     r3,r1;
        addq    r2,#1;
        st.w    (sp+4),r2;
        jmp     number_2;
number_1:
        st.w    (sp+4),r3;     // parsed number
        ld.w    r1,r1_store;
        ld.w    r3,r3_store;
        ret;

find_name:
        //TODO: implement HIDDEN
        dw      number_name;
        db      4;
        dm      "find";
find:
        dw      $+2;
        pop     r2;
        pop     r0;
        jsr     _find;
        push    r2;
        jmp     _next;
_find:
        st.w    r1_store,r1;
        st.w    r3_store,r3;
        push    r0;                 // string ptr
        push    r2;                 // string length
        push    r0;                 // reserving space for word end
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
        pop     r0;
        ld.w    r1,r1_store;
        ld.w    r3,r3_store;
        ret;
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
        jsr     _tcfa;
        push    r2;
        jmp     _next;
_tcfa:
        addq    r2,#2;
        ld.b    r0,(r2);
        add     r2,r0;
        addq    r2,#2;          // zero-terminated plus one more
        ret;

interpret_name:
        dw      tcfa_name;
        db      4;
        dm      "interpret";
interpret:
        dw      $+2;
        jsr     _word;          // r0 = string ptr, r2 = string length
        push    r0;             // might need to parse word to number
        push    r2;
        jsr     _find;          // r2 = word header ptr
        test    r2;
        beq     interpret_not_word;
        pop     r0;             // don't need the word, anymore
        pop     r0;
        jsr     _tcfa;          // r2 = codeword ptr
        ld.w    r0,(r2);
        jmp     (r0);
interpret_not_word:
        jsr     _number;
        pop     r0;         // number of remaining chars
        bne     interpret_nan;
        jmp     _next;
interpret_nan:
        // TODO handle
        nop;
interpret_is_lit:
        db      0;

// Words

double_name:
        dw      interpret_name;
        db      6;
        dm      "double";
double:
        dw      _docol,dup,plus,exit;

tdfa_name:
        dw      double_name;
        db      4;
        dm      "tdfa";
tdfa:
        dw      _docol,tcfa,incr2,exit;

quit_name:
        dw      tdfa_name;
        db      4;
        dm      "quit";
quit:
        dw      _docol;
        dw      rz,rspstore;
        dw      interpret;
        dw      branch,-8;

// Constants

rz_name:
        dw      quit_name;
        db      2;
        dm      "r0";
rz:
        dw      $+2;
        ld.w    r0,#RETURN_STACK;
        push    r0;
        jmp     _next;

// Variables

base_name:
        dw      rz_name;
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

// Start

_start:
        // set up data stack
        ld.w    r0,#EXT_RAM_LEN;
        move    sp,r0;

        // set up return stack
        ld.w    r1,#RETURN_STACK;

        ld.w    r3,#0x2000;
        jmp     _next;

buffer:
        dm      "2 3 + double ";
