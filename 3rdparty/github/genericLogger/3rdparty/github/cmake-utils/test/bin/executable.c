#include <stdlib.h>
#include <stdio.h>
#include "test.h"

int main() {
  double x = call_sin(1.1);
  fprintf(stdout, "call_sin(3.) => %f\n", call_sin(3.));
  exit(0);
}
