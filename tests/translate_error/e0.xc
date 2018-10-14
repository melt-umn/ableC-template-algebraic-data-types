#include <stdio.h>
#include <stdlib.h>

template<v>
datatype Expr {
  Add (inst Expr<v> *e1, inst Expr<v> *e2);
  Mul (inst Expr<v> *e1, inst Expr<v> *e2);
  Const (v val);
};

template<v>
datatype Expr {
  Add (inst Expr<v> *e1, inst Expr<v> *e2);
  Mul (inst Expr<v> *e1, inst Expr<v> *e2);
  Const (v val);
};

template allocate datatype Foo with malloc;

template allocate datatype Expr with malloc;

template<v>
v value(inst Expr<v, int> *e) {
  v result = 99;
  
  match (e) {
    &Add(e1,e2) -> { result = inst value<v>(e1) + inst value<v>(e2); }
    &Mul(e1,e2) -> { result = inst value<v>(e1) * inst value<v>(e2); }
    &Const(v) -> { result = v;  }
  }
  return result;
}

int main() {
  inst Expr<int> *t0 = inst malloc_Mul<int>(inst malloc_Const<int>(2), inst malloc_Const<int>(4));

  int result0 = inst value<int>(t0);
  if (result0 != 8) return 1;
  
  inst Expr<long> *t1 = inst malloc_Mul<long>(inst malloc_Const<long>(3000), 
                                              inst malloc_Mul<long>(inst malloc_Const<long>(2000),
                                                                    inst malloc_Const<long>(4000)));

  long result1 = inst value<long>(t1);
  if (result1 != 24000000000) return 2;

  inst Expr<float> *t2 = inst malloc_Add<float>(inst malloc_Mul<float>(inst malloc_Const<float>(3),
                                                                       inst malloc_Const<float>(0.5)), 
                                                inst malloc_Mul<float>(inst malloc_Const<float>(1.75),
                                                                       inst malloc_Const<float>(3)));

  float result2 = inst value<float>(t2);
  if (result2 != 6.75) return 3;

  return 0;
}
