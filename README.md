# Attention Scorer — Tiny Tapeout tile

The score-and-select half of transformer attention on one Tiny Tapeout tile: a stored
int8 query, streamed int8 keys, a serial saturating MAC, and an argmax tracker.

The TL-Verilog source (`tlv/scorer.tlv`) was produced by an LLM agent pipeline working
from a byte-exact executable specification, with every candidate gated by a
deterministic harness: SandPiper compile, simulation compared byte-for-byte against
the golden model over 7968 cycles across two independently seeded vector sets, and
latch-free synthesis. An earlier candidate passed the entire first vector set while
still violating the 64-key limit; the second seed caught it, and the agent repaired
the design through the same pipeline. `src/project.v` is the SandPiper-generated
Verilog of that repaired design. See `docs/info.md` for the protocol and test details.
