#include <alloca.h>

template<typename a>
datatype Tree {
  Node(Tree<a> *l, Tree<a> *r);
  Leaf(a val);
};

allocate_using stack;

int main() {
  Tree<int> *a = new Node(new Leaf(0), new Leaf(2));
}
