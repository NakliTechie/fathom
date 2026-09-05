# Fathom — forge. Offline only; nothing here runs in the browser (FATHOM.md §4.3).
#
#   make all PROGRAM=uart_puts      one program, every leg, through verify
#   make programs                   all three programs
#   make verify                     the C0 checkpoint on every committed artifact
#   make status                     the single perception act (SPEC §0.2)

LLVM    := /opt/homebrew/opt/llvm/bin
CLANG   := $(LLVM)/clang
CFLAGS  := --target=riscv32-unknown-elf -march=rv32i -mabi=ilp32 -O0 -g \
           -ffreestanding -fno-builtin -nostdlib

PROGRAM ?= uart_puts
PROGRAMS := uart_puts popcount chase sum
# extra translation units per program (sum is two TUs on purpose: SPEC §7.3)
EXTRA_sum := sum_lib
EXTRA := $(EXTRA_$(PROGRAM))
EXTRA_OBJS = $(addprefix $(P)/,$(addsuffix .o,$(EXTRA)))

B       := build
P       := $(B)/$(PROGRAM)
ELF     := $(P)/$(PROGRAM).elf
SIM     := $(B)/sim/obj/fathom_sim
GATES   := $(B)/synth/ibex_top_gates.v
SKY     := $(B)/synth/ibex_top_sky130.v

.PHONY: all programs program sim gates equiv toggles descent probe verify synth status clean
all: descent equiv probe
	./.venv/bin/python forge/verify.py artifacts/$(PROGRAM)/descent.json

programs:
	@for p in $(PROGRAMS); do $(MAKE) --no-print-directory all PROGRAM=$$p || exit 1; done

## program — C + crt0 -> RV32I ELF, IR, the DWARF line table, the memory image
program: $(ELF)
$(ELF): forge/program/$(PROGRAM).c $(addprefix forge/program/,$(addsuffix .c,$(EXTRA))) forge/program/crt0.S forge/program/link.ld forge/program/mkimage.py
	@mkdir -p $(P)/sim $(P)/gates
	$(CLANG) $(CFLAGS) -S -emit-llvm forge/program/$(PROGRAM).c -o $(P)/$(PROGRAM).ll
	@for t in $(EXTRA); do $(CLANG) $(CFLAGS) -S -emit-llvm forge/program/$$t.c -o $(P)/$$t.ll; done
	$(CLANG) $(CFLAGS) -c forge/program/crt0.S          -o $(P)/crt0.o
	$(CLANG) $(CFLAGS) -c forge/program/$(PROGRAM).c    -o $(P)/$(PROGRAM).o
	@for t in $(EXTRA); do $(CLANG) $(CFLAGS) -c forge/program/$$t.c -o $(P)/$$t.o; done
	ld.lld -T forge/program/link.ld $(P)/crt0.o $(P)/$(PROGRAM).o $(EXTRA_OBJS) -o $@
	$(LLVM)/llvm-dwarfdump --debug-line $@ > $(P)/line.txt
	$(LLVM)/llvm-objcopy -O binary $@ $(P)/$(PROGRAM).bin
	python3 forge/program/mkimage.py $(P)/$(PROGRAM).bin $(P)/$(PROGRAM).hex

## sim — RTL simulation (Verilator): RVFI retire trace + per-cycle stage taps
$(SIM): forge/sim/fathom_tb.sv forge/sim/fathom_mem.sv forge/sim/build.sh
	./forge/sim/build.sh
sim: $(P)/sim/retire.log
$(P)/sim/retire.log: $(ELF) $(SIM)
	$(SIM) +hex=$(P)/$(PROGRAM).hex +outdir=$(P)/sim +vcd=$(P)/sim/rtl.vcd \
	       +pc_end=$$($(LLVM)/llvm-objdump -d $(ELF) | grep -E '^[0-9a-f]+: 0000006f' | tail -1 | cut -d: -f1)

## synth — Ibex -> generic gate netlist (program-independent)
synth: $(GATES)
$(GATES): forge/synth/synth.ys forge/synth/sv2v.sh
	./forge/synth/sv2v.sh
	yosys -q -s forge/synth/synth.ys

## sky130 — Ibex -> sky130_fd_sc_hd cells (D2), and the same program on that netlist
$(SKY): forge/synth/synth_sky130.ys forge/synth/sv2v.sh
	./forge/synth/sv2v.sh
	yosys -q -s forge/synth/synth_sky130.ys
sky130: $(P)/sky130/toggles.json
$(P)/sky130/bus.log: $(SKY) $(P)/sim/retire.log forge/sim/fathom_gates_tb.sv forge/sim/fathom_mem.sv forge/sim/build_sky130.sh
	@mkdir -p $(P)/sky130
	./forge/sim/build_sky130.sh
	vvp $(B)/sky130/fathom_sky130_sim +hex=$(P)/$(PROGRAM).hex +outdir=$(P)/sky130 +vcd=$(P)/sky130/gates.vcd \
	       +halt_cycle=$$(grep '^# halt' $(P)/sim/cycle.log | sed -E 's/.*cycle ([0-9]+).*/\1/') \
	       | grep -vE '^(VCD info|WARNING: .*readmemh)'
$(P)/sky130/toggles.json: $(P)/sky130/bus.log forge/join/vcd_toggles.py
	python3 forge/join/vcd_toggles.py $(PROGRAM) sky130

## gates — the same program on the netlist (Icarus), to VCD
gates: $(P)/gates/bus.log
$(P)/gates/bus.log: $(GATES) $(P)/sim/retire.log forge/sim/fathom_gates_tb.sv forge/sim/fathom_mem.sv forge/sim/build_gates.sh
	@mkdir -p $(P)/gates
	./forge/sim/build_gates.sh
	vvp $(B)/gates/fathom_gates_sim +hex=$(P)/$(PROGRAM).hex +outdir=$(P)/gates +vcd=$(P)/gates/gates.vcd \
	       +halt_cycle=$$(grep '^# halt' $(P)/sim/cycle.log | sed -E 's/.*cycle ([0-9]+).*/\1/') \
	       | grep -vE '^(VCD info|WARNING: .*readmemh)'

## equiv — RTL == gates on the bus, every cycle
equiv: gates $(P)/sky130/bus.log
	python3 forge/join/check_equiv.py $(PROGRAM) gates
	python3 forge/join/check_equiv.py $(PROGRAM) sky130

## toggles — gate VCD -> per-cycle toggle events (join 3)
toggles: $(P)/gates/toggles.json
$(P)/gates/toggles.json: $(P)/gates/bus.log forge/join/vcd_toggles.py
	python3 forge/join/vcd_toggles.py $(PROGRAM)

## descent — the join pass: every layer -> artifacts/<program>/descent.json
descent: artifacts/$(PROGRAM)/descent.json
artifacts/$(PROGRAM)/descent.json: $(P)/sim/retire.log $(P)/gates/toggles.json $(P)/sky130/toggles.json forge/join/descent.py forge/join/probe_joins.py
	./.venv/bin/python forge/join/descent.py $(PROGRAM)

## probe — join totality, from build outputs (the verifier's ancestor)
probe: $(P)/gates/toggles.json
	python3 forge/join/probe_joins.py $(PROGRAM)

## verify — the C0 checkpoint. Reads ONLY committed artifacts + the source tree.
verify:
	@for p in $(PROGRAMS); do ./.venv/bin/python forge/verify.py artifacts/$$p/descent.json || exit 1; done

## status — the single perception act
status:
	@echo "fathom / forge"
	@for p in $(PROGRAMS); do \
	  if [ -f artifacts/$$p/descent.json ]; then \
	    ./.venv/bin/python forge/verify.py artifacts/$$p/descent.json | sed 's/^/  /'; \
	  else echo "  MISSING  artifacts/$$p/descent.json   -> make all PROGRAM=$$p"; fi; done

clean:
	rm -rf $(B)
