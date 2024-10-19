#define _YOSYS_
#include <kernel/yosys.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {

  Yosys::log_streams.push_back(&std::cout);
  Yosys::log_error_stderr = true;
  Yosys::yosys_setup();

  Yosys::yosys_design = new Yosys::RTLIL::Design;

  Yosys::run_pass("read_verilog ../../rtl/*.v");
  Yosys::run_pass("read -sv ../../rtl/*.sv");
  Yosys::run_pass("prep");
  Yosys::run_pass("opt -full");

  for (auto module : Yosys::yosys_design->modules()) {
    printf("Foo Name: %s\n", module->name.c_str());
  }

  return EXIT_SUCCESS;
}
