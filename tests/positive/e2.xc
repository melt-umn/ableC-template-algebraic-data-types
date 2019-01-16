template<a>
datatype Foo {
  A(a val);
};

struct Bar {
  Foo<struct Bar> *f;
};

int main() {
}
