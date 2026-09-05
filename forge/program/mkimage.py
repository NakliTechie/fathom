#!/usr/bin/env python3
"""forge stage: flat binary -> $readmemh image, based at the modelled MemBase.

The ELF's ROM starts at 0x8000_0080 (Ibex's reset vector is boot_addr + 0x80),
while the harness models memory from 0x8000_0000 — so the image is padded by
0x80 bytes so that word index == (addr - MemBase) / 4.
"""
import pathlib
import struct
import sys

PAD = 0x80

src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
b = b"\x00" * PAD + src.read_bytes()
b += b"\x00" * ((-len(b)) % 4)
words = struct.unpack("<%dI" % (len(b) // 4), b)
dst.write_text("".join(f"{w:08x}\n" for w in words))
print(f"image: {len(words)} words -> {dst}")
