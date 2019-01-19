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

  if (show(t0) != "&Mul(&Const(2), &Const(4))") return 1;
  if (value(t0) != 8) return 2;
  
  Expr<long> *t1 = malloc_Mul(malloc_Const(3000l),
                              malloc_Mul(malloc_Const(2000l),
                                         malloc_Const(4000l)));

  if (show(t1) != "&Mul(&Const(3000), &Mul(&Const(2000), &Const(4000)))") return 3;
  if (value(t1) != 24000000000) return 4;

  Expr<float> *t2 = malloc_Add(malloc_Mul(malloc_Const<float>(3),
                                          malloc_Const<float>(0.5)), 
                               malloc_Mul(malloc_Const<float>(1.75),
                                          malloc_Const<float>(3)));

  if (show(t2) != "&Add(&Mul(&Const(3), &Const(0.5)), &Mul(&Const(1.75), &Const(3)))") return 5;
  if (value(t2) != 6.75) return 6;

  return 0;
}
