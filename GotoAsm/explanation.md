### Prelude basic code

#### Raw

```
00000000: bb0f ef97 bb16 3131 352b 3011 1170 2aaf  ......115+0..p*.
00000010: 2a2b 2aaf 2a11 3ec2 373e 3336 3237 3036  *+*.*.>.7>362706
00000020: 3139 3638 3233 3236 3bb0 3937 8239 3936  19682326;.97.996
00000030: 3934 3037 3032 3432 3136 393e 7e8d       94070242169>~.
```

#### Tokenized

```
inString(toString(binomcdf(115,0))+"?","?"):sin(7:36270619682326ᴇ⁻97*99694070242169:\7e\8d
```

## Prelude explanation

### `inString(toString(binomcdf(115,0))+"?","?"):sin(7:36270619682326ᴇ⁻97*99694070242169`

#### `inString(toString(binomcdf(115,0))+"?","?")`
- Produces value 234:
  - binomcdf(n, p): produces list with n+1 items
  - binomcdf(115,0): list of 116 items, all being 0
  - toString(binomcdf(115,0)): string with 234 characters:
    - 2 brackets: +2
    - 116 instances of `1`: +116
    - 115 instances of commas: +115
    - total: 234
  - toString(binomcdf(115,0))+"?": string `{1,1,1,...1}?` len 234
  - inString(toString(binomcdf(115,0))+"?","?"): produces 234 because question mark is last char in 234 len string
- OP values after expression:
  - OP1: `0521000000000000000500`
  - OP2: `0082234000000000000000`
  - OP3: `3233340030303030303030`
  - OP4: `0082234000000000003030`
  - OP5: `0082234000000000000000`
  - OP6: `ea00e9000100e9001106d0` -> `234d 0d 233d 0d`
  - OP7: `0000000000000000000000`
- Ensures OP6 first instruction is valid and will not lead to any changes in execution, it creates the `jp pe, $00E900` instruction which is a no-op because the flags will never be set to "parity even" in this context.

#### `sin(7`
- Seems unnecessary, changes value in op5 but pretty sure it is clobbered, need additional investigation

#### `36270619682326ᴇ⁻97*99694070242169`
- `36270619682326ᴇ⁻97`
  - Parsed into a real in OP1, moved to OP5 so more parsing can be done using OP1: `D00624 (OP5 backing): 00 2C 36 27 06 19 68 23 26 23 00` (pretty float `3.6270619682326e−84`)
- `99694070242169`
  - Parsed into OP1, moved to OP2 so multiplication result can be stored in OP1: `D00603 (OP2 backing): 00 8D 99 69 40 70 24 21 69 00 00` (pretty float `9.9694070242169e13`)
- `*`
  - Binary-op dispatcher multiplies OP5 * Op2, product stored in OP1: `D005F8 (OP1 Backing): 00 3A 36 15 96 57 06 33 68 00 00` (pretty float `3.6159657063368e−70`)
- Turning the float into code (how OP3–OP6 get their bytes)
  - After the multiply, the OS canonicalizes the real and spreads the mantissa across OP registers. The nine low mantissa bytes from OP1 land in OP3M..OP5M, giving the opcode stream we need in OP3M/OP4M/OP5M: `36 15 96 57 06 33 68 05 00`. The internal exponent/sign formatting injects `0x0500` into OP3’s high bytes, so the first two bytes of OP3 become `15 00` (that’s why you see a leading `dec d` instead of `nop`). CEMU shows OP4 as NaN due to the exponent byte `0x15`, but the raw bytes are still the exact opcodes we use.
  - OP6 is pre-seeded with a safe sequence that will be self-patched: `EA 00 E9 00 01 00 E9 00 EA 00 D0` which disassembles as `jp pe, $00E900; ld bc, $00E900; jp pe, $00D000`. We later turn the middle three bytes (`01 00 E9`) into `ED 27 E9` at runtime.

### `\7e\8d`

In the main token dispatcher, `0x7e`, or the Graph Format token gets a special path:

```
099928     cp	a, $7e
09992A     jp	c, loc_09B7D0
```

Which leads to this logic to manufacture an index from the token value. The next byte indicates one of the formats availible (ie 0x00 is sequential, 0x01 is Simul, etc.). This byte is used to calculate an index into a table of function pointer with pointer arithmetic, without proper bounds checking:

```
09B7CA loc_09B7CA:
09B7CA     call	__IncFetch        ; consume the next byte
...
09B7CE loc_09B7CE:
09B7CE     add	a, $7e            ; a = a + 0x7e
09B7D0 loc_09B7D0:
09B7D0     sub	a, $09            ; a = a - 9
09B7D2 loc_09B7D2:
09B7D2     push	af
09B7D3     call	loc_09B9FF        ; does some general checks and causes syntax errors, no bounds check
...
09B7FB     ld	a, b                ; b := a (index reuse)
09B7FC     call	z, loc_09C13E     ; dispatch through table if bit test allowed (default)
```

```
09C13E loc_09C13E:
09C13E     ld	hl, $09c045         ; table base
09C142     push	af
09C143     ld	de, $000000
09C147     ld	e, a
09C148     add	hl, de
09C149     add	hl, de
09C14A     add	hl, de            ; hl = base + 3*a
09C14B     ld	hl, (hl)            ; load pointer from table entry
09C14D     call	loc_08C665        ; indirect jump
```

Indirect jump handler:

```
08C665 loc_08C665:
08C665     jp	(hl)
```

For the arTIfiCE V2 GotoASM exploit, a value of `0x8d` is used after `0x7e`, which leads to an index calculation of:
- `0x8d + 0x7e - 0x09 = 0x02`

While the function pointer table base is at `0x09C045`, the lowest possible offset used into the table is 0x15f (`(0x00 + 0x7e - 0x09) * 3`) therefore there are a lot of entries which begin before the real used start of the table, even though they aren't intended to be "entries".

So the index of `0x02` leads to an offset of `0x06` bytes into the table, which is at `0x09C04B`. The three bytes there point to the OP3 register backing store at `0xD0060E`, which is where execution will jump to when the `jp (hl)` is executed.

> how this exploit was most likely found:
> It's likely the attacker searched for register controlled indirect jumps and filtered out those which were called/reachable from BASIC execution.
> from there, only a few sites remain, and the graph format table is one of them.
> Another possibility is that the attacker searched for the address of several places controlled by BASIC code (OP registers, string buffers, etc) in memory and found out what accessed nearby regions. By doing this, an attacker could potentially determine that an arbitrary jump to an arbitrary address was possible.

## Code execution explained

The OP3 - OP6 bytes are carefully crafted to self-patch and redirect execution to the BASIC token stream right after the `0x7e` token.
- Build the constant `0xED` from the incoming A=2
- Patch OP6 from `01 00 E9` into `ED 27 E9`
- Point HL at the OS’s “current fetch pointer” variable (`D0231A`)
- Execute `LD HL,(HL)` then `JP (HL)` to jump to the byte after `0x7e` in the BASIC payload

Assembly of OP3–OP6 (only the relevant parts shown):
```
D0060E: 36 15         ld (hl), $15       ; write 0x15 at OP3[0]
D00610: 96            sub a, (hl)        ; A = 0x02 - 0x15 = 0xED (wrap)
D00611: 57            ld d, a            ; D = 0xED
D00612: 06 33         ld b, $33
D00614: 68            ld l, b            ; L = 0x33 -> HL = D00633
D00615: 05            dec b
D00616: 00            nop
D00619: 72            ld (hl), d         ; [D00633] = 0xED
D00625: 2C            inc l              ; L = 0x34 -> HL = D00634
D00626: 36 27         ld (hl), $27       ; [D00634] = 0x27  => ED 27 at D00633–34
D00628: 06 19         ld b, $19
D0062A: 68            ld l, b            ; L = 0x19 -> HL = D00619
D0062B: 23            inc hl             ; HL = D0061A
D0062C: 26 23         ld h, $23          ; HL = D0231A (upper byte stays D0)
D0062F: EA 00 E9 00   jp pe, $00E900     ; not taken here; fall through
D00633: ED 27         ld hl, (hl)        ; HL = [D0231A] = 0x0C0117
D00635: E9            jp (hl)            ; jump to the byte after 0x7e
```

OP6 before and after the self-patch:

```
D0062F: EA00E900    ; jp pe, $00E900
D00633: 0100E900    ; ld bc, $00E900
D00637: EA00D000    ; jp pe, $00D000
```

```
D0062F: EA00E900
D00633: ED27E9      ; ld hl,(hl) ; jp (hl)
D00636: 00
D00637: EA00D000
```

- A=2 on entry is deliberate. `ld (hl),$15` then `sub a,(hl)` computes `0x02 - 0x15 = 0xED`, giving the ED prefix byte without any immediate data.
- `ld l,b` aims HL at `D00633`, then `ld (hl),d` and `inc l`/`ld (hl),$27` rewrite `01 00 E9` into `ED 27 E9`.
- `ld h,$23` (with the preserved upper byte `D0`) makes HL = `D0231A`, the OS variable that holds the current fetch pointer. That pointer was advanced by `__IncFetch` when the `0x7e` byte was consumed in the main token dispatcher, so it now points to the byte after `0x7e`.
- `jp pe, $00E900` is a safe guard that’s not taken in this path, so execution naturally reaches the patched `ED 27 E9`
- `ED 27` (eZ80 ADL) loads the 24-bit HL from `[HL]`, and `E9` jumps to it, transferring control to the BASIC token stream right after `0x7e` (ACE entry)
