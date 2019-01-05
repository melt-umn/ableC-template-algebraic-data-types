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
inline distance get_x(Point<distance, angle> p) {
  return match(p) (Cart(x, y) -> x;
                   Polar(r, t) -> r * cos(t););
}

template<distance, angle>
inline distance get_y(Point<distance, angle> p) {
  return match(p) (Cart(x, y) -> y;
                   Polar(r, t) -> r * sin(t););
}

template<distance, angle>
distance dist(Point<distance, angle> p1,
              Point<distance, angle> p2) {
  distance d_x = get_x<distance, angle>(p1) - get_x<distance, angle>(p2);
  distance d_y = get_y<distance, angle>(p1) - get_y<distance, angle>(p2);
  return (distance)sqrt(d_x * d_x + d_y * d_y);
}

int main () {
  Point<int, float>
    p1 = Cart<int, float>(2, 3),
    p2 = Polar<int, float>(2, M_PI / 4);
  int d1 = dist<int, float>(p1, p2);
  if (d1 != 2)
    return 1;
  
  Point<float, double>
    p3 = Polar<float, double>(2, M_PI / 2),
    p4 = Cart<float, double>(-2.23607f, 0);
  float d2 = dist<float, double>(p3, p4);
  if ((d2 - 3) * (d2 - 3) > 0.001)
    return 2;

  return 0;
}
