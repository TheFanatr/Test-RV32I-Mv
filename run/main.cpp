#include "Vrv32i.h"
#include "verilated.h"
#include "verilated_fst_c.h"
Vrv32i *top;
VerilatedContext *contextp;
VerilatedFstC *tfp;

void step() {
  contextp->timeInc(1);
  top->eval();
  tfp->dump(contextp->time());
}

int main(int argc, char **argv) {
  contextp = new VerilatedContext;
  Verilated::traceEverOn(true);
  contextp->commandArgs(argc, argv);
  tfp = new VerilatedFstC;
  top = new Vrv32i{contextp};
  top->trace(tfp, 99);

  tfp->open("run.fst");
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

  // while (!contextp->gotFinish()) {
  for (int i = 0; i < 300; i++) {
    contextp->timeInc(1);

    top->clk = !top->clk;

    top->eval();
    tfp->dump(contextp->time());
  }

  tfp->close();

  delete top;
  delete contextp;
  return 0;
}
