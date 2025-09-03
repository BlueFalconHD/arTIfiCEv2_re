.nolist
#include "rom/ti84pce.inc"
.list

	.org UserMem-2
	.db tExtTok,tAsm84CeCmp

OS_ClrLCDFull      .equ    0020808h
OS_DrawStatusBar   .equ    0021A3Ch
OS_PutS            .equ    00207C0h
OS_GetKey          .equ    0020D8Ch
OS_SetupHome       .equ    0021798h
OS_ForceCmdNoChar  .equ    0021FA8h

TBL_BASE           .equ    009C045h ; table base

start:
        ld      de, start

        push    bc
        push    de
        call    OS_SetupHome
        pop     de
        pop     bc

        push    bc
        push    de
        call    OS_ClrLCDFull
        pop     de
        pop     bc

        push    bc
        push    de
        call    OS_DrawStatusBar
        pop     de
        pop     bc

        ld      hl, row
        ld      (hl), 0
        ld      hl, base
        ld      (hl), 0
        ld      hl, page
        ld      (hl), 0

page_loop:
        push    bc
        push    de
        call    OS_ClrLCDFull
        call    OS_DrawStatusBar
        call    OS_SetupHome
        pop     de
        pop     bc
        ld      hl, row
        ld      (hl), 0
        ld      a, (page)
        add     a, a
        add     a, a
        add     a, a
        ld      e, a
        ld      b, 8
line_loop:
        push    bc
        ld      a, e
        add     a, 075h
        nop

        ld      hl, TBL_BASE
        push    bc
        ld      bc, 000000h
        ld      c, a
        add     hl, bc
        add     hl, bc
        add     hl, bc
        pop     bc

        push    bc
        ld      a, (hl)
        call    put_ptr_lo
        inc     hl
        ld      a, (hl)
        call    put_ptr_mid
        inc     hl
        ld      a, (hl)
        call    put_ptr_hi
        pop     bc

        ld      hl, line
        ld      bc, 000002h
        add     hl, bc
        ld      a, e
        call    hex_out_byte

        ld      hl, line
        ld      bc, 000007h
        add     hl, bc
        ld      a, e
        add     a, 075h
        call    hex_out_byte

        ld      hl, line
        ld      bc, 00000Ch
        add     hl, bc
        call    get_ptr_hi
        call    hex_out_byte
        call    get_ptr_mid
        call    hex_out_byte
        call    get_ptr_lo
        call    hex_out_byte

        ld      a, (row)
        ld      (CURROW), a
        xor     a
        ld      (CURCOL), a

        ld      hl, line
        push    bc
        push    de
        call    OS_PutS
        pop     de
        pop     bc

        ld      hl, row
        inc     (hl)

        inc     e
        pop     bc
        dec     b
        jp      nz, line_loop

        ld      a, (page)
        ld      hl, page_line
        ld      bc, 000005h
        add     hl, bc
        call    hex_out_byte
        ld      a, 8
        ld      (CURROW), a
        xor     a
        ld      (CURCOL), a
        ld      hl, page_line
        push    bc
        push    de
        call    OS_PutS
        pop     de
        pop     bc

key_wait:
        push    bc
        push    de
        call    OS_GetKey
        pop     de
        pop     bc
        cp      kClear
        jp      z, exit_program
        cp      kLeft
        jr      z, prev_page
        cp      kRight
        jr      z, next_page
        jp      key_wait

prev_page:
        ld      a, (page)
        or      a
        jp      z, page_loop
        dec     a
        ld      (page), a
        jp      page_loop

next_page:
        ld      a, (page)
        inc     a
        ld      (page), a
        jp      page_loop

exit_program:
        push    bc
        push    de
        call    OS_SetupHome
        pop     de
        pop     bc
        jp      OS_ForceCmdNoChar

hex_out_byte:
        push    bc
        ld      b, a
        ld      a, b
        rrca
        rrca
        rrca
        rrca
        and     0Fh
        call    hex_digit
        ld      (hl), a
        inc     hl
        ld      a, b
        and     0Fh
        call    hex_digit
        ld      (hl), a
        inc     hl
        pop     bc
        ret

hex_digit:
        and     0Fh
        add     a, '0'
        cp      '9'+1
        jr      c, hex_done
        add     a, 7
hex_done:
        ret

put_ptr_lo:
        push    hl
        ld      hl, ptr_lo
        ld      (hl), a
        pop     hl
        ret

put_ptr_mid:
        push    hl
        ld      hl, ptr_mid
        ld      (hl), a
        pop     hl
        ret

put_ptr_hi:
        push    hl
        ld      hl, ptr_hi
        ld      (hl), a
        pop     hl
        ret

get_ptr_lo:
        push    hl
        ld      hl, ptr_lo
        ld      a, (hl)
        pop     hl
        ret

get_ptr_mid:
        push    hl
        ld      hl, ptr_mid
        ld      a, (hl)
        pop     hl
        ret

get_ptr_hi:
        push    hl
        ld      hl, ptr_hi
        ld      a, (hl)
        pop     hl
        ret

base:       .db     0
row:        .db     0
page:       .db     0
ptr_lo:     .db     0
ptr_mid:    .db     0
ptr_hi:     .db     0
lines_left: .db     0

line:       .db "v=00 A=00 P=000000",0
page_line:       .db "Page=00",0
