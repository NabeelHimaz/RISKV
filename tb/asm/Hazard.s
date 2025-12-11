# RISC-V Assembly Testbench for Hazard Validation
# -----------------------------------------------
# Initial Setup
addi x1, x0, 10      # x1 = 10
addi x2, x0, 20      # x2 = 20
addi x10, x0, 100    # x10 = 100 (Base address for memory tests)

# ----------------------------------------------------------------
# TEST 1: MEM -> EX Forwarding (Distance 1)
# ----------------------------------------------------------------
# The ADD produces 30. It will be in the MEM stage when the SUB needs it.
# Without forwarding, SUB would read old data (0) or stall unnecessarily.
add  x3, x1, x2      # x3 = 10 + 20 = 30  <-- Produces Value
sub  x4, x3, x1      # x4 = 30 - 10 = 20  <-- CONSUMES x3 IMMEDIATELY (Hazard!)

# ----------------------------------------------------------------
# TEST 2: WB -> EX Forwarding (Distance 2)
# ----------------------------------------------------------------
# The AND produces a result. We insert a NOP. The OR needs the result.
# The AND will be in WB stage when OR is in EX stage.
and  x5, x1, x2      # x5 = 10 & 20 = 0   (1010 & 10100 = 00000)
addi x0, x0, 0       # NOP                <-- Buffer instruction
or   x6, x5, x2      # x6 = 0 | 20 = 20   <-- CONSUMES x5 FROM WRITEBACK

# ----------------------------------------------------------------
# TEST 3: Load-Use Hazard (Stall Requirement)
# ----------------------------------------------------------------
# We store 55 to memory, then load it back.
# The ADD attempts to use the loaded value immediately.
# Forwarding is impossible because the data is still in RAM.
# The Hazard Unit MUST insert a stall (bubble).
addi x11, x0, 55     # x11 = 55
sw   x11, 0(x10)     # Store 55 at address 100
lw   x7, 0(x10)      # Load 55 into x7    <-- Load Instruction
add  x8, x7, x1      # x8 = 55 + 10 = 65  <-- USE Hazard! (Must Stall)

# ----------------------------------------------------------------
# END
# ----------------------------------------------------------------
# Infinite loop to catch the simulator
beq  x0, x0, 0