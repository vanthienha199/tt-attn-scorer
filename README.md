# Attention Scorer — Tiny Tapeout tile

The score-and-select half of transformer attention on one Tiny Tapeout tile: a stored
int8 query, streamed int8 keys, a serial saturating MAC, and an argmax tracker.

The TL-Verilog source (`tlv/scorer.tlv`) was produced by an LLM agent pipeline working
from a byte-exact executable specification, with every candidate gated by a
deterministic harness: SandPiper compile, 3410-cycle byte-exact simulation against the
golden model, and latch-free synthesis. `src/project.v` is the SandPiper-generated
Verilog of the first candidate that passed every gate. See `docs/info.md` for the
protocol and test details.
