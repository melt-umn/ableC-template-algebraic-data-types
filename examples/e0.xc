#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#ifndef M_PI
#define M_PI (3.14159265358979323846)
#endif

template<distance, angle>
datatype Point {
  Cart(distance x, distance y);
  Polar(distance r, angle t);
};

template<distance, angle>
inline distance get_x(inst Point<distance, angle> p) {
  return match(p) (Cart(x, y) -> x;
                   Polar(r, t) -> r * cos(t););
}

template<distance, angle>
inline distance get_y(inst Point<distance, angle> p) {
  return match(p) (Cart(x, y) -> y;
                   Polar(r, t) -> r * sin(t););
}

template<distance, angle>
distance dist(inst Point<distance, angle> p1,
              inst Point<distance, angle> p2) {
  distance d_x = inst get_x<distance, angle>(p1) - inst get_x<distance, angle>(p2);
  distance d_y = inst get_y<distance, angle>(p1) - inst get_y<distance, angle>(p2);
  return (distance)sqrt(d_x * d_x + d_y * d_y);
}

int main () {
  inst Point<int, float>
    p1 = inst Cart<int, float>(2, 3),
    p2 = inst Polar<int, float>(2, M_PI / 4);
  printf("distance 1: %d\n", inst dist<int, float>(p1, p2));
  
  inst Point<float, double>
    p3 = inst Polar<float, double>(2, M_PI / 2),
    p4 = inst Cart<float, double>(-2.23607f, 0);
  printf("distance 2: %f\n", inst dist<float, double>(p3, p4));
}
