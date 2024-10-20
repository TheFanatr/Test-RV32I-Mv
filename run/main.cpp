#include "Vrv32i.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "uartsim.h"
#include <cstdio>
#include <csignal>

Vrv32i *top;
VerilatedContext *contextp;
VerilatedFstC *tfp;

UARTSIM *uart;

void step() {
  //contextp->timeInc(1);
  top->eval();
  //tfp->dump(contextp->time());
}

void soft_close(...) {
  tfp->close();
  uart->kill();

  delete uart;
  delete top;
  delete contextp;
  delete tfp;

  exit(0);
}

void (*const soft_close_p)(int) = reinterpret_cast<void (*)(int)>(soft_close);

int main(int argc, char **argv) {
  std::signal(SIGINT, soft_close_p);
  std::signal(SIGTERM, soft_close_p);
  std::signal(SIGQUIT, soft_close_p);

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

  tfp->open("run.fst");

  /*while (!top->booted) {
    top->clk = 1;
    top->eval();

    top->clk = 0;
    top->eval();

    top->rx = (*uart)(top->tx);

    // contextp->timeInc(1);
    // tfp->dump(contextp->time());
  }*/
  // while (!top->booted) {
  //   top->clk = !top->clk;
  //   top->rx = (*uart)(top->tx);

  //   top->eval();
  //   tfp->dump(contextp->time());
  //   contextp->timeInc(1);
  // }

  // printf("Booted\n");

  //while (!contextp->gotFinish()) {
  while (true) {
   //for (int i = 0; i < 10000; i++) {
    top->clk = 1;
    top->eval();
    if(top->booted) tfp->dump(contextp->time());
    if(top->booted) contextp->timeInc(1);

    top->clk = 0;
    top->eval();
    if(top->booted) tfp->dump(contextp->time());
    if(top->booted) contextp->timeInc(1);

    top->rx = (*uart)(top->tx);
  }

  tfp->close();

  delete top;
  delete contextp;
  return 0;
}
