#!/usr/bin/env python3

import argparse, struct, sys

SIG                   = b"**TI83F*"
SIG_TAIL              = bytes([0x1A, 0x0A])
MYSTERY_BYTE          = 0x13
COMMENT               = "Fighting for freedom of peaceful assembly!" # must be 42 bytes or padded to 42 bytes

FLAG                  = 0x0D
UNKNOWN               = 0x00

# these must match the values set in the constant 9byte in the exploit assembly
FILE_TYPE             = 0x05
PROGRAM_NAME          = b"A\x00\x00\x00\x00\x00\x00\x00"

VERSION               = 0x0C
IS_ARCHIVED           = 0x80

HEADER_SIZE           = 55
META_SIZE             = 19

def le16(n: int) -> bytes:
    return struct.pack("<H", n & 0xFFFF)

def make_header(body_len: int) -> bytes:
    meta_and_body_len = META_SIZE + body_len

    comment_bytes = COMMENT.encode("ascii", "strict")[:42].ljust(42, b"\x00")

    hdr  = bytearray()
    hdr += SIG
    hdr += SIG_TAIL
    hdr += bytes([MYSTERY_BYTE])
    hdr += comment_bytes
    hdr += le16(meta_and_body_len)
    assert len(hdr) == HEADER_SIZE
    return bytes(hdr)

def make_meta(body_len: int) -> bytes:
    L_bc = body_len + 2

    meta  = bytearray()
    meta += bytes([FLAG])
    meta += bytes([UNKNOWN])
    meta += le16(L_bc)
    meta += bytes([FILE_TYPE])
    assert len(PROGRAM_NAME) == 8
    meta += PROGRAM_NAME
    meta += bytes([VERSION])
    meta += bytes([IS_ARCHIVED])
    meta += le16(L_bc)
    meta += le16(body_len)
    assert len(meta) == META_SIZE
    return bytes(meta)

def checksum(meta: bytes, body: bytes) -> bytes:
    s = (sum(meta) + sum(body)) & 0xFFFF
    return le16(s)

def main():
    ap = argparse.ArgumentParser(description="Make a TI-8XP from an arbitrary body")
    ap.add_argument("body", help="path to binary program body")
    ap.add_argument("out",  help="output .8xp path")
    ap.add_argument("--name", help="program name (1-8 ASCII chars)", dest="name", default=None)
    ap.add_argument("--comment", "--description", help="program description/comment (ASCII, max 42 chars)", dest="comment", default=None)
    args = ap.parse_args()

    body = open(args.body, "rb").read()
    if len(body) > 0xFFFF:
        print("warning: body > 65535 bytes; lengths are 16-bit and will wrap", file=sys.stderr)

    global COMMENT, PROGRAM_NAME
    program_name_bytes = PROGRAM_NAME
    if args.name is not None:
        try:
            name_ascii = args.name.encode("ascii", "strict")
        except UnicodeEncodeError:
            print("error: --name must be ASCII", file=sys.stderr)
            sys.exit(2)
        if len(name_ascii) == 0 or len(name_ascii) > 8:
            print("error: --name length must be between 1 and 8 characters", file=sys.stderr)
            sys.exit(2)
        program_name_bytes = name_ascii.ljust(8, b"\x00")
    header_comment = COMMENT
    if args.comment is not None:
        try:
            comment_ascii = args.comment.encode("ascii", "strict")
        except UnicodeEncodeError:
            print("error: --comment must be ASCII", file=sys.stderr)
            sys.exit(2)
        if len(comment_ascii) > 42:
            print("warning: --comment longer than 42 bytes; it will be truncated", file=sys.stderr)
        header_comment = args.comment
    COMMENT = header_comment
    PROGRAM_NAME = program_name_bytes
    hdr  = make_header(len(body))
    meta = make_meta(len(body))
    cks  = checksum(meta, body)

    with open(args.out, "wb") as f:
        f.write(hdr)
        f.write(meta)
        f.write(body)
        f.write(cks)

    total = len(hdr) + len(meta) + len(body) + 2
    print(f"wrote {args.out}: {total} bytes")
    print(f"header.meta_and_body_length = {struct.unpack('<H', hdr[-2:])[0]} (expected {META_SIZE + len(body)})")
    print(f"meta.body_and_checksum_length = {struct.unpack('<H', meta[2:4])[0]} (expected {len(body)+2})")
    print(f"meta.body_length = {struct.unpack('<H', meta[-2:])[0]} (expected {len(body)})")

if __name__ == "__main__":
    main()
