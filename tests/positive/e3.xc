template<a>
datatype Tree {
  Node(inst Tree<a> *l, inst Tree<a> *r);
  Leaf(a val);
};

int main() {
  inst Tree<int> a;
}
