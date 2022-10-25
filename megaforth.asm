// TODO Error handling - need figure out MP error system
// TODO Implement more primitives
// TODO Try to compile jonesforth.f
// TODO Halt somehow - busy loop?
// TODO Write to display - need figure out how to write to display and how to do it from Forth
// TODO Better number parsing
// TODO "Multi-line" strings - treat null as white space, require double null to terminate input?
// TODO Implement "hidden"?

include "Megaprocessor_defs.asm";

RETURN_STACK        equ 0x6000;     // totally made up number, feel free to change

_F_IMMED            equ 0x80;
_F_LENMASK          equ 0x1f;

// NB: We're using r1 as the return stack pointer and r3 as the "instruction" pointer.
//     They can be used in code, but their values need to be stored and restored,
//     before calling _next.
//
//     Update: I might revise this and store them in memory, somewhere...

// NB: In Jones Forth, the headers and code are together in one place, but the
//     Megaprocessor does not handle mixnig code and data well. It sometimes thinks
//     data just before code is code and then it gets everything wrong, after that,
//     and it can only be fixed by adding random padding. Hence, I've split headers
//     and code into two separate sections for Mega Forth.

        jmp     _start;

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

_start:
        // set up data stack
        ld.w    r0,#EXT_RAM_LEN;
        move    sp,r0;

        // set up return stack
        ld.w    r1,#RETURN_STACK;

        ld.w    r3,#cold_start;
        jmp     _next;

_docol:
        move    r0,r3;
        move    r3,r2;
        addq    r3,#2;
        addq    r1,#-2;
        move    r2,r1;
        st.w    (r2),r0;

        // fall through to _next

_next:
        ld.w    r0,(r3++);
        move    r2,r0;
        ld.w    r0,(r2);
        jmp     (r0);

// Code

// Primitives

exit_code:
        move    r2,r1;
        ld.w    r0,(r2);
        addq    r1,#2;
        move    r3,r0;
        jmp     _next;

drop_code:
        pop     r0;
        jmp     _next;

swap_code:
        pop     r0;
        pop     r2;
        push    r0;
        push    r2;
        jmp     _next;

dup_code:
        ld.w    r0,(sp+0);
        push    r0;
        jmp     _next;

over_code:
        ld.w    r0,(sp+2);
        push    r0;
        jmp     _next;

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

nrot_code:
        st.w    r1_store,r1;
        pop     r0;
        pop     r1;
        pop     r2;
        push    r0;
        push    r2;
        push    r1;
        ld.w    r1,r1_store;
        jmp     _next;

twodrop_code:
        pop     r0;
        pop     r0;
        jmp     _next;

twodup_code:
        jsr     _twodup;
        jmp     _next;
_twodup:
        ld.w    r0,(sp+0);
        ld.w    r2,(sp+2);
        ret;

twoswap_code:
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

qdup_code:
        ld.w    r0,(sp+0);
        beq     qdup_end;
        push    r0;
qdup_end:
        jmp     _next;

incr_code:
        pop     r0;
        addq    r0,#1;
        push    r0;
        jmp     _next;

decr_code:
        pop     r0;
        addq    r0,#-1;
        push    r0;
        jmp     _next;

incr2_code:
        pop     r0;
        addq    r0,#2;
        push    r0;
        jmp     _next;

decr2_code:
        pop     r0;
        addq    r0,#-2;
        push    r0;
        jmp     _next;

branch_code:
        ld.w    r0,(r3);
        add     r3,r0;      // add 2 more?
        jmp     _next;

plus_code:
        nop;
        nop;
        nop;
        pop     r0;
        pop     r2;
        add     r0,r2;
        push    r0;
        jmp     _next;

minus_code:
        nop;
        nop;
        nop;
        pop     r0;
        pop     r2;
        sub     r0,r2;
        push    r0;
        jmp     _next;

mul_code:
        st.w    r1_store,r1;
        st.w    r3_store,r3;    // r3 gets set by muls, although not currently read
        pop     r0;
        pop     r1;
        muls;
        push    r2;             // ignore overflow
        ld.w    r3,r3_store;
        ld.w    r1,r1_store;
        jmp     _next;

divmod_code:
        st.w    r1_store,r1;
        st.w    r3_store,r3;
        pop     r1;             // divisor
        pop     r0;             // dividend
        divs;
        push    r3;             // remainder
        push    r2;             // quotient
        ld.w    r3,r3_store;
        ld.w    r1,r1_store;
        jmp     _next;

equals_code:
        pop     r0;
        pop     r2;
        sub     r0,r2;          // 0 is falsy, all-1s is truthy
        beq     equals_equal;
        clr     r0;
        addq    r0,#-1;
equals_equal:
        inv     r0;
        push    r0;
        jmp     _next;

notequals_code:
        pop     r0;
        pop     r2;
        sub     r0,r2;
        beq     notequals_equal;
        clr     r0;
        addq    r0,#-1;
notequals_equal:
        push    r0;
        jmp     _next;

lessthan_code:
        pop     r0;
        pop     r2;
        cmp     r2,r0;
        blt     lessthan_lt;
        clr     r0;
        jmp     lessthan_ret;
lessthan_lt:
        clr     r0;
        addq    r0,#-1;
lessthan_ret:
        push    r0;
        jmp     _next;

greaterthan_code:
        pop     r0;
        pop     r2;
        cmp     r2,r0;
        bgt     greaterthan_gt;
        clr     r0;
        jmp     greaterthan_ret;
greaterthan_gt:
        clr     r0;
        addq    r0,#-1;
greaterthan_ret:
        push    r0;
        jmp     _next;

lit_code:
        ld.w    r0,(r3);
        push    r0;
        addq    r3,#2;
        jmp     _next;

fetch_code:
        pop     r2;
        ld.w    r0,(r2);
        push    r0;
        jmp     _next;

rspstore_code:
        pop     r1;
        jmp     _next;

key_code:
        jsr     _key;
        push    r0;
        jmp     _next;
_key:
        ld.w    r2,(currkey);
        ld.b    r0,(r2++);
        // TODO: if key is 0, halt
        st.w    currkey,r2;
        ret;

word_code:
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

number_code:
        // Returns number of unparsed characters on top of stack followed by parsed number
        //TODO: bases > 10, need to parse a - z
        //TODO: error handling
        jsr     _number;
        jmp     _next;
_number:
        st.w    r1_store,r1;
        st.w    r3_store,r3;
        clr     r0;
        addq    r0,#1;
        push    r0;
        ld.w    r2,(sp+6);     // string ptr
        ld.b    r1,(r2);       // str ascii
        ld.b    r0,#0x2d;       // hyphen
        cmp     r0,r1;
        bne     number_pos;
        clr     r0;
        addq    r0,#-1;
        st.w    (sp+0),r0;
        ld.w    r0,(sp+4);     //string length
        addq    r0,#-1;
        st.w    (sp+4),r0;
        addq    r2,#1;
        st.w    (sp+6),r2;
number_pos:
        clr     r3;
number_loop:
        ld.b    r1,(r2);       // str ascii
        addq    r2,#1;
        st.w    (sp+6),r2;
        ld.w    r0,#0x30;      // ascii code for 0
        sub     r1,r0;
        add     r3,r1;
        ld.w    r0,(sp+4);     //string length
        addq    r0,#-1;
        st.w    (sp+4),r0;
        beq     number_end;
        move    r0,r3;
        ld.b    r1,base_var;
        mulu;
        move    r3,r2;
        ld.w    r2,(sp+6);     // string ptr
        jmp     number_loop;
number_end:
        pop     r0;
        move    r1,r3;
        muls;
        st.w    (sp+4),r2;     // parsed number
        ld.w    r1,r1_store;
        ld.w    r3,r3_store;
        ret;

find_code:
        //TODO: implement HIDDEN
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
        ld.b    r3,#_F_LENMASK;
        and     r1,r3;
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

tcfa_code:
        nop;
        nop;
        nop;
        st.w    r3_store,r3;
        pop     r2;             // link ptr
        jsr     _tcfa;
        push    r2;
        ld.w    r3,r3_store;
        jmp     _next;
_tcfa:
        addq    r2,#2;
        ld.b    r0,(r2);
        ld.b    r3,#_F_LENMASK;
        and     r0,r3;
        add     r2,r0;
        addq    r2,#2;          // zero-terminated plus one more
        ret;

comma_code:
        pop     r0;
        jsr     _comma;
        jmp     _next;
_comma:
        ld.w    r2,here_var;
        st.w    (r2++),r0;
        st.w    here_var,r2;
        ret;

lbrac_code:
        clr     r0;
        st.w    state_var,r0;
        jmp     _next;

rbrac_code:
        ld.w    r0,#1;
        st.w    state_var,r0;
        jmp     _next;

create_code:
        st.w    r1_store,r1;
        st.w    r3_store,r3;
        ld.w    r0,latest_var;
        ld.w    r2,here_var;
        st.w    (r2++),r0;
        pop     r0;             // word length
        st.b    (r2++),r0;
        pop     r3;             // word ptr
        move    r1,r3;
        add     r1,r0;          // end of word ptr
create_copy_word:
        ld.b    r0,(r3++);
        st.b    (r2++),r0;
        cmp     r1,r3;
        bne     create_copy_word;
        ld.b    r0,#0;
        st.b    (r2++),r0;      // MP strings are zero terminated
        ld.w    r3,here_var;
        st.w    latest_var,r3;
        st.w    here_var,r2;
        ld.w    r3,r3_store;
        ld.w    r1,r1_store;
        jmp     _next;

interpret_code:
        st.w    r3_store,r3;
        jsr     _word;          // r0 = string ptr, r2 = string length
        push    r0;             // might need to parse word to number
        push    r2;
        jsr     _find;          // r2 = word header ptr
        test    r2;
        beq     interpret_not_word;
        pop     r0;             // don't need the word string, anymore
        pop     r0;
        push    r2;
        jsr     _tcfa;          // r2 = codeword ptr
        pop     r3;
        addq    r3,#2;
        ld.b    r0,(r3);        // length+flags
        ld.w    r3,#_F_IMMED;
        and     r0,r3;
        bne     interpret_execute;
        ld.w    r0,state_var;
        beq     interpret_execute;
        move    r0,r2;
        jsr     _comma;
        jmp     interpret_next;
interpret_execute:
        ld.w    r3,r3_store;
        ld.w    r0,(r2);
        jmp     (r0);
interpret_not_word:
        jsr     _number;
        pop     r0;             // number of remaining chars, number now top of data stack
        test    r0;
        bne     interpret_nan;
        ld.w    r0,state_var;
        beq     interpret_next;
        ld.w    r0,#lit;
        jsr     _comma;
        pop     r0;
        jsr     _comma;
interpret_next:
        ld.w    r3,r3_store;
        jmp     _next;
interpret_nan:
        // TODO handle
        nop;

// Constants

rz_code:
        ld.w    r0,#RETURN_STACK;
        push    r0;
        jmp     _next;

f_lenmask_code:
        ld.w    r0,#_F_LENMASK;
        push    r0;
        jmp     _next;

// Variables

base_code:
        ld.w    r0,#base_var;
        push    r0;
        jmp     _next;

state_code:
        ld.w    r0,#state_var;
        push    r0;
        jmp     _next;

here_code:
        ld.w    r0,#here_var;
        push    r0;
        jmp     _next;

latest_code:
        ld.w    r0,#latest_var;
        push    r0;
        jmp     _next;

// Headers

// Primitives Headers

exit_header:
        dw      0;
        db      4;
        dm      "exit";
exit:
        dw      exit_code;

drop_header:
        dw      exit_header;
        db      4;
        dm      "drop";
drop:
        dw      drop_code;

swap_header:
        dw      drop_header;
        db      4;
        dm      "swap";
swap:
        dw      swap_code;

dup_header:
        dw      swap_header;
        db      3;
        dm      "dup";
dup:
        dw      dup_code;

over_header:
        dw      dup_header;
        db      4;
        dm      "over";
over:
        dw      over_code;

rot_header:
        dw      over_header;
        db      3;
        dm      "rot";
rot:
        dw      rot_code;

nrot_header:
        dw      rot_header;
        db      4;
        dm      "rot-";
nrot:
        dw      nrot_code;

twodrop_header:
        dw      nrot_header;
        db      5;
        dm      "2drop";
twodrop:
        dw      twodrop_code;

twodup_header:
        dw      twodrop_header;
        db      4;
        dm      "2dup";
twodup:
        dw      twodup_code;

twoswap_header:
        dw      twodup_header;
        db      5;
        dm      "2swap";
twoswap:
        dw      twoswap_code;

qdup_header:
        dw      twoswap_header;
        db      4;
        dm      "?dup";
qdup:
        dw      qdup_code;

incr_header:
        dw      qdup_header;
        db      2;
        dm      "1+";
incr:
        dw      incr_code;

decr_header:
        dw      incr_header;
        db      2;
        dm      "1-";
decr:
        dw      decr_code;

incr2_header:
        dw      decr_header;
        db      2;
        dm      "2+";
incr2:
        dw      incr2_code;

decr2_header:
        dw      incr2_header;
        db      2;
        dm      "2-";
decr2:
        dw      decr2_code;

branch_header:
        dw      decr2_header;
        db      6;
        dm      "branch";
branch:
        dw      branch_code;

plus_header:
        dw      branch_header;
        db      1;
        dm      "+";
plus:
        dw      plus_code;

minus_header:
        dw      plus_header;
        db      1;
        dm      "-";
minus:
        dw      minus_code;

mul_header:
        dw      minus_header;
        db      1;
        dm      "*";
mul:
        dw      mul_code;

divmod_header:
        dw      mul_header;
        db      4;
        dm      "/mod";
divmod:
        dw      divmod_code;

equals_header:
        dw      divmod_header;
        db      1;
        dm      "=";
equals:
        dw      equals_code;

notequals_header:
        dw      equals_header;
        db      2;
        dm      "<>";
notequals:
        dw      notequals_code;

lessthan_header:
        dw      notequals_header;
        db      1;
        dm      "<";
lessthan:
        dw      lessthan_code;

greaterthan_header:
        dw      lessthan_header;
        db      1;
        dm      ">";
greaterthan:
        dw      greaterthan_code;

lit_header:
        dw      greaterthan_header;
        db      3;
        dm      "lit";
lit:
        dw      lit_code;

fetch_header:
        dw      lit_header;
        db      1;
        dm      "@";
fetch:
        dw      fetch_code;

rspstore_header:
        dw      fetch_header;
        db      4;
        dm      "rsp!";
rspstore:
        dw      rspstore_code;

key_header:
        dw      rspstore_header;
        db      3;
        dm      "key";
key:
        dw      key_code;

word_header:
        dw      key_header;
        db      4;
        dm      "word";
word:
        dw      word_code;

number_header:
        dw      word_header;
        db      6;
        dm      "number";
number:
        dw      number_code;

find_header:
        dw      number_header;
        db      4;
        dm      "find";
find:
        dw      find_code;

tcfa_header:
        dw      find_header;
        db      4;
        dm      ">cfa";
tcfa:
        dw      tcfa_code;

comma_header:
        dw      tcfa_header;
        db      1;
        dm      ",";
comma:
        dw      comma_code;

lbrac_header:
        dw      comma_header;
        db      _F_IMMED+1;
        dm      "[";
lbrac:
        dw      lbrac_code;

rbrac_header:
        dw      lbrac_header;
        db      1;
        dm      "]";
rbrac:
        dw      rbrac_code;

create_header:
        dw      rbrac_header;
        db      6;
        dm      "create";
create:
        dw      create_code;

interpret_header:
        dw      create_header;
        db      9;
        dm      "interpret";
interpret:
        dw      interpret_code;

// Built-in Words

double_header:
        dw      interpret_header;
        db      6;
        dm      "double";
double:
        dw      _docol,dup,plus,exit;

tdfa_header:
        dw      double_header;
        db      4;
        dm      "tdfa";
tdfa:
        dw      _docol,tcfa,incr2,exit;

quit_header:
        dw      tdfa_header;
        db      4;
        dm      "quit";
quit:
        dw      _docol;
        dw      rz,rspstore;
        dw      interpret;
        dw      branch,-8;

colon_header:
        dw      quit_header;
        db      1;
        dm      ":";
colon:
        dw      _docol;
        dw      word,create;
        dw      lit,_docol,comma;
        dw      rbrac;
        dw      exit;

semicolon_header:
        dw      colon_header;
        db      _F_IMMED+1;
        dm      ";";
semicolon:
        dw      _docol;
        dw      lit,exit,comma;
        dw      lbrac;
        dw      exit;

// Constant Headers

rz_header:
        dw      semicolon_header;
        db      2;
        dm      "r0";
rz:
        dw      rz_code;

f_lenmask_header:
        dw      rz_header;
        db      9;
        dm      "f_lenmask";
f_lenmask:
        dw      f_lenmask_code;

// Variable Headers

base_header:
        dw      f_lenmask_header;
        db      4;
        dm      "base";
base:
        dw      base_code;

state_header:
        dw      base_header;
        db      5;
        dm      "state";
state:
        dw      state_code;

here_header:
        dw      state_header;
        db      4;
        dm      "here";
here:
        dw      here_code;

latest_header:
        dw      here_header;
        db      6;
        dm      "latest";
latest:
        dw      latest_code;

cold_start:
        dw      quit;

currkey:
        dw      input_buffer;

word_buffer:
        ds      32;

base_var:
        db      10;

state_var:
        dw      0;          // 0 = executing, non-zero = compiling

latest_var:
        dw      latest_header;

r1_store:
        dw;

r3_store:
        dw;

input_buffer:
        dm      "-43 2 + : / /mod swap drop ; ";

here_var:
        dw      $+2;
