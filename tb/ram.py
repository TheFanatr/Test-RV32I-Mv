import cocotb
import os
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray
from cocotb.runner import get_runner
from pathlib import Path

async def reset_dut(dut):
    dut.clk_en.value = 0
    dut.rst.value = 1
    await Timer(3, units="ns")
    dut.clk_en.value = 1
    dut.rst.value = 0

@cocotb.test()
async def test_ram(dut):
    cocotb.start_soon(Clock(dut.clk, 1, units='ns').start())
    reset_dut(dut)

    dut.clk_en.value = 1
    await Timer(1, units="ns")
    for addr in range(8):
        data = 2_000_000_000 + addr
        dut.i_write_addr.value = addr
        dut.i_write_data.value = data
        dut.i_write_enable.value = 1
        dut.i_byte_enable.value = 0b1111
        await Timer(1, units="ns")
        dut.i_write_enable.value = 0
        await Timer(1, units="ns")
        dut.i_read_addr.value = addr
        dut.i_read_enable.value = 1
        await Timer(5, units="ns")
        assert dut.o_read_data.value == data, str(dut.o_read_data.value)




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