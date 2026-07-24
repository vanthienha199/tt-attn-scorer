<!---
This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.
-->

## How it works

This tile is the score-and-select half of transformer attention: it stores an 8-element
int8 query vector, computes a dot product against each key vector streamed in over the
data bus, and tracks the highest score and its key index. One int8 multiplier and one
saturating int16 accumulator are shared serially across dimensions, so a key is scored
in 8 cycles with almost no area.

The design was written in TL-Verilog. The TL-Verilog source was produced by an LLM
agent pipeline working from a byte-exact executable specification, and every candidate
was gated by a deterministic harness: SandPiper compile, simulation compared
byte-for-byte against the golden model over 7968 cycles across two independently
seeded vector sets, and a latch-free synthesis check. An earlier candidate passed the
entire first vector set while still violating the 64-key limit; the second seed caught
it, and the agent repaired the design through the same pipeline. That repaired design
is what is in this repository.

## How to test

Commands are driven on `uio[1:0]` and sampled every rising clock edge:

- `01` LOAD_Q: each cycle's `ui` byte fills the next query slot (8 total). The 8th
  byte arms the scorer: best score resets to -32768, key counter to 0.
- `10` STREAM_K: each cycle's `ui` byte is one key dimension. Every 8th byte completes
  a key; a strictly greater score replaces the best, ties keep the earlier key.
  Partial keys interrupted by another command are discarded.
- `11` READ: `uo` rotates through {best index, score high byte, score low byte}.
- `00` IDLE.

The cocotb test in `test/` replays 7968 vectors covering saturation, ties, interrupted
transactions, exact 64/65/66-key boundaries, read-interrupted streams, and mid-run
resets, and checks every output byte against the pre-computed golden model output.

## External hardware

None. LEDs on the demo board can display the winning key index during READ.
