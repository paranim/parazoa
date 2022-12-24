An immutable, persistent `Map`, `Set`, and `Vec` for Nim, based on and inspired by the ones in Clojure.

Read [the API docs](https://paranim.github.io/parazoa/) and check out [the tests](https://github.com/paranim/parazoa/blob/master/tests/test1.nim) for examples of how to use them.

Persistent data structures provide immutability without any expensive cloning, thanks to structural sharing. The basic design comes from Phil Bagwell's HAMT (hash array mapped trie), first made immutable by Rich Hickey in Clojure.

Why use persistent data structures in Nim? It's commonly believed that they're slow, but that depends on your use case. Do you find yourself making copies of your data defensively so you can retain its original value before mutating it?

Persistent data structures may *improve* your performance, since "cloning" them is just a matter of copying a ref! They can also be faster at equality comparisons, because if they have the same underlying pointer, we know they are equal and can short-circuit the comparison.
