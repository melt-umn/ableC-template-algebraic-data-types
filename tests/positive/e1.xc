#include <stdio.h>
#include <stdlib.h>
#include <string.xh>

template<v>
datatype Expr {
  Add (inst Expr<v> *e1, inst Expr<v> *e2);
  Mul (inst Expr<v> *e1, inst Expr<v> *e2);
  Const (v val);
};

template allocate datatype Expr with malloc;

template<v>
v value(inst Expr<v> *e) {
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

  if (show(t0) != "&Mul(&Const(2), &Const(4))") return 1;
  if (inst value<int>(t0) != 8) return 2;
  
  inst Expr<long> *t1 = inst malloc_Mul<long>(inst malloc_Const<long>(3000), 
                                              inst malloc_Mul<long>(inst malloc_Const<long>(2000),
                                                                    inst malloc_Const<long>(4000)));

  if (show(t1) != "&Mul(&Const(3000), &Mul(&Const(2000), &Const(4000)))") return 3;
  if (inst value<long>(t1) != 24000000000) return 4;

  inst Expr<float> *t2 = inst malloc_Add<float>(inst malloc_Mul<float>(inst malloc_Const<float>(3),
                                                                       inst malloc_Const<float>(0.5)), 
                                                inst malloc_Mul<float>(inst malloc_Const<float>(1.75),
                                                                       inst malloc_Const<float>(3)));

  if (show(t2) != "&Add(&Mul(&Const(3), &Const(0.5)), &Mul(&Const(1.75), &Const(3)))") return 5;
  if (inst value<float>(t2) != 6.75) return 6;

  return 0;
}
