template<a>
datatype Foo {
  A(a val);
};

struct Bar {
  inst Foo<struct Bar> *f;
};

int main() {
}
