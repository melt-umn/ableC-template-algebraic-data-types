#include <stdio.h>
#include <stdlib.h>
#include <string.xh>

template<v>
datatype Expr {
  Add (Expr<v> *e1, Expr<v> *e2);
  Mul (Expr<v> *e1, Expr<v> *e2);
  Const (v val);
};

template allocate datatype Expr with malloc;

template<v>
v value(Expr<v> *e) {
  v result = 99;
  
  match (e) {
    &Add(e1,e2) -> { result = value(e1) + value(e2); }
    &Mul(e1,e2) -> { result = value(e1) * value(e2); }
    &Const(v) -> { result = v;  }
  }
  return result;
}

int main() {
  Expr<int> *t0 = malloc_Mul(malloc_Const(2), malloc_Const(4));

  int result0 = value<int>(t0);
  printf("value(%s): %d\n", show(t0).text, result0);
  if (result0 != 8) return 1;
  
  Expr<long> *t1 = malloc_Mul(malloc_Const(3000l), 
                              malloc_Mul(malloc_Const(2000l),
                                         malloc_Const(4000l)));

  long result1 = value(t1);
  printf("value(%s): %ld\n", show(t1).text, result1);
  if (result1 != 24000000000) return 2;

  Expr<float> *t2 = malloc_Add(malloc_Mul(malloc_Const<float>(3),
                                          malloc_Const<float>(0.5)), 
                               malloc_Mul(malloc_Const<float>(1.75),
                                          malloc_Const<float>(3)));

  float result2 = value(t2);
  printf("value(%s): %f\n", show(t2).text, result2);
  if (result2 != 6.75) return 3;

  return 0;
}
