#include <stdlib.h>

template<typename a>
datatype Tree {
  Node(Tree<a> *l, Tree<a> *r);
  Leaf(a val);
};

template allocate datatype Tree with malloc prefix m;

int main() {
  Tree<int> *a = mNode(mLeaf(0), mLeaf(2));
}
