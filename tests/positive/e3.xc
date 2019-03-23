template<typename a>
datatype Tree {
  Node(Tree<a> *l, Tree<a> *r);
  Leaf(a val);
};

int main() {
  Tree<int> a;
}
