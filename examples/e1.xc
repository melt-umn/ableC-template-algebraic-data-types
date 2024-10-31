#include <stdio.h>
#include <stdlib.h>
#include <string.xh>

template<typename v>
datatype Expr {
  Add (Expr<v> *e1, Expr<v> *e2);
  Mul (Expr<v> *e1, Expr<v> *e2);
  Const (v val);
};

template<typename v>
v value(Expr<v> *e) {
  v result = 99;
  
  match (e) {
    &Add(e1,e2) -> { result = value(e1) + value(e2); }
    &Mul(e1,e2) -> { result = value(e1) * value(e2); }
    &Const(v) -> { result = v;  }
  }
  return result;
}

allocate_using heap;

int main() {
  Expr<int> *t0 = new Mul(new Const(2), new Const(4));

  int result0 = value<int>(t0);
  printf("value(%s): %d\n", show(t0).text, result0);
  if (result0 != 8) return 1;
  
  Expr<long> *t1 = new Mul(new Const(3000l), 
                           new Mul(new Const(2000l), new Const(4000l)));

  long result1 = value(t1);
  printf("value(%s): %ld\n", show(t1).text, result1);
  if (result1 != 24000000000) return 2;

  Expr<float> *t2 = new Add(new Mul(new Const<float>(3),
                                    new Const<float>(0.5)), 
                            new Mul(new Const<float>(1.75),
                                    new Const<float>(3)));

  float result2 = value(t2);
  printf("value(%s): %f\n", show(t2).text, result2);
  if (result2 != 6.75) return 3;

  return 0;
}
