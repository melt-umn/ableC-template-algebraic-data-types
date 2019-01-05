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
    &Add(e1,e2) -> { result = value<v>(e1) + value<v>(e2); }
    &Mul(e1,e2) -> { result = value<v>(e1) * value<v>(e2); }
    &Const(v) -> { result = v;  }
  }
  return result;
}

int main() {
  Expr<int> *t0 = malloc_Mul<int>(malloc_Const<int>(2), malloc_Const<int>(4));

  int result0 = value<int>(t0);
  printf("value(%s): %d\n", show(t0).text, result0);
  if (result0 != 8) return 1;
  
  Expr<long> *t1 = malloc_Mul<long>(malloc_Const<long>(3000), 
                                    malloc_Mul<long>(malloc_Const<long>(2000),
                                                     malloc_Const<long>(4000)));

  long result1 = value<long>(t1);
  printf("value(%s): %ld\n", show(t1).text, result1);
  if (result1 != 24000000000) return 2;

  Expr<float> *t2 = malloc_Add<float>(malloc_Mul<float>(malloc_Const<float>(3),
                                                        malloc_Const<float>(0.5)), 
                                      malloc_Mul<float>(malloc_Const<float>(1.75),
                                                        malloc_Const<float>(3)));

  float result2 = value<float>(t2);
  printf("value(%s): %f\n", show(t2).text, result2);
  if (result2 != 6.75) return 3;

  return 0;
}
