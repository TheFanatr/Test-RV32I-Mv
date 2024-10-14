#include "Vrv32i.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "uartsim.h"
#include <cstdio>
Vrv32i *top;
VerilatedContext *contextp;
VerilatedFstC *tfp;

UARTSIM *uart;

void step() {
  //contextp->timeInc(1);
  top->eval();
  //tfp->dump(contextp->time());
}

int main(int argc, char **argv) {
  contextp = new VerilatedContext;
  Verilated::traceEverOn(true);
  contextp->commandArgs(argc, argv);
  tfp = new VerilatedFstC;
  top = new Vrv32i{contextp};
  top->trace(tfp, 99);

  uart = new UARTSIM(8880);
  uart->setup(0x005161);

  top->clk = 0;
  step();

 
  top->clk = !top->clk;
  step();

  top->clk = !top->clk;
  step();

  top->rst = 1;
  top->clk = !top->clk;
  step();

  top->clk = !top->clk;
  step();
    top->clk = !top->clk;
  step();
    top->clk = !top->clk;
  step();

  top->rst = 0;
  top->clk = 0;

  top->clk = !top->clk;
  step();

  top->clk = !top->clk;
  step();
  top->clk_en = 1;
  top->clk = !top->clk;
  step();

  while (!top->booted) {
      // contextp->timeInc(1);

    	  top->clk = 1;
				top->eval();
				top->clk = 0;
				top->eval();

      top->rx = (*uart)(top->tx);
      //  tfp->dump(contextp->time());
  }

  tfp->open("run.fst");
  while (!contextp->gotFinish()) {
    	  top->clk = !top->clk;
        top->rx = (*uart)(top->tx);

				top->eval();
        tfp->dump(contextp->time());
        contextp->timeInc(1);
  }

  tfp->close();

  delete top;
  delete contextp;
  return 0;
}
