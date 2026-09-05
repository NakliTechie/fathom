# Fathom — forge. Offline only; nothing here runs in the browser (FATHOM.md §4.3).
#
# C0 scope: the legs proven so far. C1 turns this into one deterministic target
# producing a committed artifact.

LLVM   := /opt/homebrew/opt/llvm/bin
CLANG  := $(LLVM)/clang
CFLAGS := --target=riscv32-unknown-elf -march=rv32i -mabi=ilp32 -O0 -g \
          -ffreestanding -fno-builtin -nostdlib

B      := build
PROG   := $(B)/uart_puts.elf
SIM    := $(B)/sim/obj/fathom_sim

.PHONY: all program sim synth probe clean status
all: probe equiv toggles

## program — C + crt0 -> RV32I ELF, IR and the DWARF line table
program: $(PROG)
$(PROG): forge/program/uart_puts.c forge/program/crt0.S forge/program/link.ld
	@mkdir -p $(B)/sim
	$(CLANG) $(CFLAGS) -S -emit-llvm forge/program/uart_puts.c -o $(B)/uart_puts.ll
	$(CLANG) $(CFLAGS) -c forge/program/crt0.S      -o $(B)/crt0.o
	$(CLANG) $(CFLAGS) -c forge/program/uart_puts.c -o $(B)/uart_puts.o
	ld.lld -T forge/program/link.ld $(B)/crt0.o $(B)/uart_puts.o -o $@
	$(LLVM)/llvm-dwarfdump --debug-line $@ > $(B)/line.txt
	$(LLVM)/llvm-objcopy -O binary $@ $(B)/uart_puts.bin
	python3 forge/program/mkimage.py $(B)/uart_puts.bin $(B)/uart_puts.hex

## sim — RTL simulation: RVFI retire trace + per-cycle stage occupancy
sim: $(B)/sim/retire.log
$(B)/sim/retire.log: $(PROG) forge/sim/fathom_tb.sv forge/sim/fathom_mem.sv forge/sim/build.sh
	./forge/sim/build.sh
	$(SIM) +hex=$(B)/uart_puts.hex +outdir=$(B)/sim +vcd=$(B)/sim/rtl.vcd \
	       +pc_end=$$($(LLVM)/llvm-objdump -d $(PROG) | grep -E '^[0-9a-f]+: 0000006f' | tail -1 | cut -d: -f1)

## synth — Ibex -> gate netlist
synth: $(B)/synth/ibex_top_gates.v
$(B)/synth/ibex_top_gates.v: forge/synth/synth.ys forge/synth/sv2v.sh
	./forge/synth/sv2v.sh
	yosys -q -s forge/synth/synth.ys

## gates — the same program on the synthesised netlist, to VCD
gates: $(B)/gates/bus.log
$(B)/gates/bus.log: $(B)/synth/ibex_top_gates.v $(B)/sim/retire.log forge/sim/fathom_gates_tb.sv forge/sim/fathom_mem.sv forge/sim/build_gates.sh
	./forge/sim/build_gates.sh
	vvp $(B)/gates/fathom_gates_sim +hex=$(B)/uart_puts.hex +outdir=$(B)/gates +vcd=$(B)/gates/gates.vcd \
	       +halt_cycle=$$(grep '^# halt' $(B)/sim/cycle.log | sed -E 's/.*cycle ([0-9]+).*/\1/') \
	       | grep -vE '^(VCD info|WARNING: .*readmemh)'

## equiv — RTL == gates on the bus, every cycle
equiv: gates
	python3 forge/join/check_equiv.py

## toggles — gate VCD -> per-cycle toggle events (join 3)
toggles: gates
	python3 forge/join/vcd_toggles.py

## probe — join totality. The C0 checkpoint's ancestor.
probe: sim
	python3 forge/join/probe_joins.py

## status — the single perception act (SPEC §0.2)
status:
	@echo "fathom / forge"
	@for f in $(PROG) $(B)/sim/retire.log $(B)/synth/ibex_top_gates.v $(B)/gates/bus.log; do \
	  if [ -f $$f ]; then echo "  present  $$f"; else echo "  MISSING  $$f"; fi; done
	@echo "  next: make probe"

clean:
	rm -rf $(B)
