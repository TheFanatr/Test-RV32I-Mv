import cocotb
import os
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray
from cocotb.runner import get_runner
from pathlib import Path

@cocotb.test()
async def test_ram(dut):
    for cycle in range(10):
        dut.clk.value = 0
        await Timer(1, units="ns")
        dut.clk.value = 1
        await Timer(1, units="ns")


def test_ram_runner():
    sim = os.getenv("SIM", "verilator")

    proj_path = Path(__file__).resolve().parent

    sources = [proj_path / ".." / "rtl" / "ram.sv"]
    inc = [proj_path / ".." / "rtl" ]

    # --coverage --trace --trace-fst --trace-structs
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="ram",
        always=True,
        includes=inc,
        build_args=["--trace", "--trace-fst", "--trace-structs"],
        defines={"TESTING": True}
    )

    runner.test(hdl_toplevel="ram", test_module="ram,", waves=True)


if __name__ == "__main__":
    test_ram_runner()