I set a breakpoint on 09C13E. Execution lands there with the following state:

### Top stack entries:
D1A85A 09B800
D1A85D 08C65D
D1A860 000005
D1A863 0001E1
D1A866 08C45A
D1A869 0005BB
D1A86C 061D47
D1A86F 061CF1
D1A872 000000

### Registers:
af: 254, a: 2, f: 84,
bc: 0C0200, b: 2, c: 0,
de: 1, d: 0, e: 1,
hl: 0C0118, h: 1, l: 24
ix: D005C1, ixh: 5, ixl: 193,
iy: D00080, iyh: 0, iyl: 128

```
09C13E loc_09C13E:
09C13E     ld	hl, $09c045
09C142     push	af
09C143     ld	de, $000000
09C147     ld	e, a
09C148     add	hl, de
09C149     add	hl, de
09C14A     add	hl, de
09C14B     ld	hl, (hl)
09C14D     call	loc_08C665
09C151     res	0, (iy+$07)
09C155     pop	af
09C156     ld	hl, $09c166
09C15A     ld	bc, $00000b
09C15E     cpir
09C160     ret	nz
09C161     call	__DrawStatusBarInfo
09C165     ret
09C166     ld	h, h
```

Once it reaches `09C14B`, the data at address pointed to by HL (= 09C04B) is D0060E. Then it hits the

```
08C665 loc_08C665:
08C665     jp	(hl)
```

Where it jumps to `D0060E`:

```
D00603  OP2:
D00603     00            nop
D00604     8D            adc a, l
D00605  OP2M:
D00605     99            sbc a, c
D00606     69            ld l, c
D00607     4070          ld.sis (hl), b
D00609     24            inc h
D0060A     21690000      ld hl, $000069
D0060E  OP3:
D0060E     00            nop
D0060F     00            nop
D00610  OP3M:
D00610     3615          ld (hl), $15
D00612     96            sub a, (hl)
D00613     57            ld d, a
D00614     0633          ld b, $33
D00616     68            ld l, b
D00617     05            dec b
D00618     00            nop
D00619  OP4:
D00619     00            nop
D0061A     72            ld (hl), d
D0061B  OP4M:
D0061B     00            nop
D0061C     00            nop
D0061D     00            nop
D0061E     00            nop
D0061F     00            nop
D00620     00            nop
D00621     00            nop
D00622     00            nop
D00623     00            nop
D00624  OP5:
D00624     00            nop
D00625     2C            inc l
D00626  OP5M:
D00626     3627          ld (hl), $27
D00628     0619          ld b, $19
D0062A     68            ld l, b
D0062B     23            inc hl
D0062C     2623          ld h, $23
D0062E     00            nop
D0062F  OP6:
D0062F     EA00E900      jp pe, $00E900
D00633     0100E900      ld bc, $00E900
D00637     EA00D000      jp pe, $00D000
D0063B     00            nop
D0063C     00            nop
D0063D     00            nop
D0063E     00            nop
D0063F     00            nop
D00640     00            nop
D00641     00            nop
D00642     00            nop
D00643     00            nop
D00644     00            nop
D00645     00            nop
D00646     00            nop
D00647     00            nop
D00648     00            nop
D00649     00            nop
D0064A     00            nop
D0064B     00            nop
D0064C     00            nop
D0064D     00            nop
D0064E     00            nop
D0064F     00            nop
D00650     00            nop
D00651     00            nop
D00652     00            nop
D00653     00            nop
```

After `D00612` executes (`96            sub a, (hl)`), af = ED93 (a=237, f=147).

After `D0061A` executes (`72            ld (hl), d`), D00633=`ED00E9        in0 b, ($E9)`, af=ED03, bc=0C3200, de=00ED02, hl=D00633, ix=D005C1

At `D00625` L increments to become D00634, and D00626 (`3627          ld (hl), $27`) sets up these instructions:

```
D00633     ED27          ld hl, (hl)
D00635     E9            jp (hl)
```

Before `D0062F` (`EA00E900      jp pe, $00E900`) executes, register status is af=ED01, bc=0C1900, de=00ED02, hl=D0231A, ix=D005C1

The jump is skipped, and D00633 (`ED27          ld hl, (hl)`) loads `0C0117` into hl.

Then `D00635` (`E9            jp (hl)`) is run, which jumps to the byte after 0x7e in the basic payload, leading to ACE.

The final state of the OP register memory before execution:

```
D00603  OP2:
D00603     00            nop
D00604     8D            adc a, l
D00605  OP2M:
D00605     99            sbc a, c
D00606     69            ld l, c
D00607     4070          ld.sis (hl), b
D00609     24            inc h
D0060A     21690000      ld hl, $000069
D0060E  OP3:
D0060E     15            dec d
D0060F     00            nop
D00610  OP3M:
D00610     3615          ld (hl), $15
D00612     96            sub a, (hl)
D00613     57            ld d, a
D00614     0633          ld b, $33
D00616     68            ld l, b
D00617     05            dec b
D00618     00            nop
D00619  OP4:
D00619     00            nop
D0061A     72            ld (hl), d
D0061B  OP4M:
D0061B     00            nop
D0061C     00            nop
D0061D     00            nop
D0061E     00            nop
D0061F     00            nop
D00620     00            nop
D00621     00            nop
D00622     00            nop
D00623     00            nop
D00624  OP5:
D00624     00            nop
D00625     2C            inc l
D00626  OP5M:
D00626     3627          ld (hl), $27
D00628     0619          ld b, $19
D0062A     68            ld l, b
D0062B     23            inc hl
D0062C     2623          ld h, $23
D0062E     00            nop
D0062F  OP6:
D0062F     EA00E900      jp pe, $00E900
D00633     ED27          ld hl, (hl)
D00635     E9            jp (hl)
D00636     00            nop
D00637     EA00D000      jp pe, $00D000
D0063B     00            nop
D0063C     00            nop
D0063D     00            nop
D0063E     00            nop
D0063F     00            nop
D00640     00            nop
D00641     00            nop
D00642     00            nop
D00643     00            nop
D00644     00            nop
D00645     00            nop
D00646     00            nop
D00647     00            nop
D00648     00            nop
D00649     00            nop
D0064A     00            nop
D0064B     00            nop
D0064C     00            nop
D0064D     00            nop
D0064E     00            nop
D0064F     00            nop
D00650     00            nop
D00651     00            nop
D00652     00            nop
D00653     00            nop
D00654     00            nop
D00655     00            nop
D00656     00            nop
D00657     00            nop
D00658     00            nop
D00659     00            nop
D0065A     00            nop
```
