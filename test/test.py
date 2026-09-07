# SPDX-License-Identifier: Apache-2.0
# Golden-model conformance test for the attention scorer.
# Replays test/vectors.txt (cmd byte + data byte per line; cmd f = reset pulse) and
# compares uo_out after every clock edge against test/expected.txt, which was
# produced by the byte-exact executable spec (model/golden.py in the design repo).

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge

HERE = os.path.dirname(os.path.abspath(__file__))


def load_lines(name):
    with open(os.path.join(HERE, name)) as f:
        return [l.strip() for l in f if l.strip()]


@cocotb.test()
async def test_scorer_conformance(dut):
    vectors = load_lines("vectors.txt")
    expected = load_lines("expected.txt")
    assert len(vectors) == len(expected)

    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await FallingEdge(dut.clk)

    mismatches = 0
    for i, (vec, exp) in enumerate(zip(vectors, expected)):
        cmd_s, data_s = vec.split()
        if cmd_s == "f":
            dut.rst_n.value = 0
            await ClockCycles(dut.clk, 2)
            dut.rst_n.value = 1
            await FallingEdge(dut.clk)
            got = int(dut.uo_out.value)
        else:
            dut.ui_in.value = int(data_s, 16)
            dut.uio_in.value = int(cmd_s, 16) & 0x3
            await RisingEdge(dut.clk)
            # Sample half a period after the edge so gate-level clock-tree and
            # buffer delays have settled (1 ns is enough for RTL but not GL).
            await FallingEdge(dut.clk)
            got = int(dut.uo_out.value)
        want = int(exp, 16)
        if got != want:
            mismatches += 1
            if mismatches <= 10:
                dut._log.error(
                    f"cycle {i+1}: cmd={cmd_s} data={data_s} expected {want:02x} got {got:02x}")
    assert mismatches == 0, f"{mismatches} of {len(vectors)} cycles mismatched"
    dut._log.info(f"all {len(vectors)} cycles match the golden model")
