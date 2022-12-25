import hashes
from math import `^`
from strutils import nil

const
  parazoaBits* {.intdefine.} = 5
  branchWidth = 1 shl parazoaBits
  mask = branchWidth - 1

type
  NodeKind = enum
    Branch,
    Leaf,
  KeyError* = object of CatchableError
  IndexError* = object of CatchableError

func copyRef[T](node: T): T =
  new result
  if node != nil:
    result[] = node[]

type
  MapNode*[K, V] = ref object
    case kind: NodeKind
    of Branch:
      nodes: array[branchWidth, MapNode[K, V]]
    of Leaf:
      keyHash: Hash
      key: K
      value: V
  Map*[K, V] = object
    root: MapNode[K, V]
    size: Natural

func initMap*[K, V](): Map[K, V]  =
  ## Returns a new `Map`
  result.root = MapNode[K, V](kind: Branch)

func len*[K, V](m: Map[K, V]): Natural =
  ## Returns the number of key-value pairs in the `Map`
  m.size

func add[K, V](res: var Map[K, V], node: MapNode[K, V], level: int, keyHash: Hash, key: K, value: V)  =
  let
    index = (keyHash shr level) and mask
    child = node.nodes[index]
  if child == nil:
    node.nodes[index] = MapNode[K, V](kind: Leaf, keyHash: keyHash, key: key, value: value)
    res.size += 1
  else:
    case child.kind:
    of Branch:
      let newChild = copyRef(child)
      node.nodes[index] = newChild
      add(res, newChild, level + parazoaBits, keyHash, key, value)
    of Leaf:
      if child.keyHash == keyHash:
        let newChild = copyRef(child)
        newChild.value = value
        node.nodes[index] = newChild
      else:
        res.size -= 1
        let newChild = MapNode[K, V](kind: Branch)
        node.nodes[index] = newChild
        add(res, newChild, level + parazoaBits, child.keyHash, child.key, child.value)
        add(res, newChild, level + parazoaBits, keyHash, key, value)

func add[K, V](m: Map[K, V], keyHash: Hash, key: K, value: V): Map[K, V]  =
  var res = m
  res.root = copyRef(m.root)
  add(res, res.root, 0, keyHash, key, value)
  res

func add*[K, V](m: Map[K, V], key: K, value: V): Map[K, V]  =
  ## Adds a new key-value pair to the `Map`
  add(m, hash(key), key, value)

func del[K, V](res: var Map[K, V], node: MapNode[K, V], level: int, keyHash: Hash)  =
  let
    index = (keyHash shr level) and mask
    child = node.nodes[index]
  if child == nil:
    discard
  else:
    case child.kind:
    of Branch:
      let newChild = copyRef(child)
      node.nodes[index] = newChild
      del(res, newChild, level + parazoaBits, keyHash)
    of Leaf:
      if child.keyHash == keyHash:
        node.nodes[index] = nil
        res.size -= 1

func del[K, V](m: Map[K, V], keyHash: Hash): Map[K, V]  =
  var res = m
  res.root = copyRef(m.root)
  del(res, res.root, 0, keyHash)
  res

func del*[K, V](m: Map[K, V], key: K): Map[K, V] =
  ## Deletes the key-value pair at `key` from the `Map`
  del(m, hash(key))

func get[K, V](node: MapNode[K, V], level: int, keyHash: Hash): V =
  if node == nil:
    # this can happen if the Map was not initialized
    raise newException(KeyError, "Key not found")
  let
    index = (keyHash shr level) and mask
    child = node.nodes[index]
  if child == nil:
    raise newException(KeyError, "Key not found")
  else:
    case child.kind:
    of Branch:
      get(child, level + parazoaBits, keyHash)
    of Leaf:
      if child.keyHash == keyHash:
        child.value
      else:
        raise newException(KeyError, "Key not found")

func get[K, V](m: Map[K, V], keyHash: Hash): V =
  get(m.root, 0, keyHash)

func get*[K, V](m: Map[K, V], key: K): V =
  ## Returns the value at `key`, or raises an exception if not found
  get(m, hash(key))

func getOrDefault*[K, V](m: Map[K, V], key: K, defaultValue: V): V  =
  ## Returns the value at `key`, or `defaultValue` if not found
  try:
    get(m, hash(key))
  except KeyError:
    defaultValue

func contains*[K, V](m: Map[K, V], key: K): bool  =
  ## Returns whether `key` is inside the `Map`
  try:
    discard get(m, key)
    true
  except KeyError:
    false

iterator pairs*[K, V](m: Map[K, V]): (K, V) =
  ## Iterates over the key-value pairs in the `Map`
  if m.root != nil:
    var stack: seq[tuple[parent: MapNode[K, V], index: int]] = @[(m.root, 0)]
    while stack.len > 0:
      let (parent, index) = stack[stack.len-1]
      if index == parent.nodes.len:
        discard stack.pop()
        if stack.len > 0:
          stack[stack.len-1].index += 1
      else:
        let node = parent.nodes[index]
        if node == nil:
          stack[stack.len-1].index += 1
        else:
          case node.kind:
          of Leaf:
            yield (node.key, node.value)
            stack[stack.len-1].index += 1
          of Branch:
            stack.add((node, 0))

iterator keys*[K, V](m: Map[K, V]): K =
  ## Iterates over the keys in the `Map`
  for (k, v) in m.pairs:
    yield k

iterator values*[K, V](m: Map[K, V]): V =
  ## Iterates over the values in the `Map`
  for (k, v) in m.pairs:
    yield v

func `==`*[K, V](m1: Map[K, V], m2: Map[K, V]): bool  =
  ## Returns whether the `Map`s are equal
  if m1.len != m2.len:
    false
  elif m1.root == m2.root:
    true
  else:
    for (k, v) in m1.pairs:
      try:
        if m2.get(k) != v:
          return false
      except KeyError:
        return false
    true

func toMap*[K, V](arr: openArray[(K, V)]): Map[K, V] =
  ## Returns a `Map` containing the key-value pairs in `arr`
  var m = initMap[K, V]()
  for (k, v) in arr:
    m = m.add(k, v)
  m

proc `[]`[K, V](m: Map[K, V]; key: K): V =
  ## get key
  m.get(key)

func `$`*[K, V](m: Map[K, V]): string =
  ## Returns a string representing the `Map`
  var x = newSeq[string]()
  for (k, v) in m.pairs:
    x.add($k & ": " & $v)
  "{" & strutils.join(x, ", ") & "}"

func hash*[K, V](m: Map[K, V]): Hash  =
  ## Returns a `Hash` of the `Map`
  var h: Hash = 0
  for keyVal in m.pairs:
    h = h !& hash(keyVal)
  !$h

func `&`*[K, V](m1: Map[K, V], m2: Map[K, V]): Map[K, V] =
  ## Returns a merge of the `Map`s
  var res = m1
  for (k, v) in m2.pairs:
    res = res.add(k, v)
  res

func add*[K, V](m1: var Map[K, V], m2: Map[K, V]) =
  ## Merges the second `Map` into the first one
  ## (This sets the var to a new `Map` -- the old `Map` is not mutated)
  m1 = m1 & m2

type
  SetNode*[T] = ref object
    case kind: NodeKind
    of Branch:
      nodes: array[branchWidth, SetNode[T]]
    of Leaf:
      keyHash: Hash
      key: T
  Set*[T] = object
    root: SetNode[T]
    size: Natural

func initSet*[T](): Set[T]  =
  ## Returns a new `Set`
  result.root = SetNode[T](kind: Branch)

func len*[T](s: Set[T]): Natural =
  ## Returns the number of values in the `Set`
  s.size

func incl[T](res: var Set[T], node: SetNode[T], level: int, keyHash: Hash, key: T)  =
  let
    index = (keyHash shr level) and mask
    child = node.nodes[index]
  if child == nil:
    node.nodes[index] = SetNode[T](kind: Leaf, keyHash: keyHash, key: key)
    res.size += 1
  else:
    case child.kind:
    of Branch:
      let newChild = copyRef(child)
      node.nodes[index] = newChild
      incl(res, newChild, level + parazoaBits, keyHash, key)
    of Leaf:
      if child.keyHash == keyHash:
        discard
      else:
        res.size -= 1
        let newChild = SetNode[T](kind: Branch)
        node.nodes[index] = newChild
        incl(res, newChild, level + parazoaBits, child.keyHash, child.key)
        incl(res, newChild, level + parazoaBits, keyHash, key)

func incl[T](s: Set[T], keyHash: Hash, key: T): Set[T]  =
  var res = s
  res.root = copyRef(s.root)
  incl(res, res.root, 0, keyHash, key)
  res

func incl*[T](s: Set[T], key: T): Set[T]  =
  ## Adds a new value to the `Set`
  incl(s, hash(key), key)

func excl[T](res: var Set[T], node: SetNode[T], level: int, keyHash: Hash)  =
  let
    index = (keyHash shr level) and mask
    child = node.nodes[index]
  if child == nil:
    discard
  else:
    case child.kind:
    of Branch:
      let newChild = copyRef(child)
      node.nodes[index] = newChild
      excl(res, newChild, level + parazoaBits, keyHash)
    of Leaf:
      if child.keyHash == keyHash:
        node.nodes[index] = nil
        res.size -= 1

func excl[T](s: Set[T], keyHash: Hash): Set[T]  =
  var res = s
  res.root = copyRef(s.root)
  excl(res, res.root, 0, keyHash)
  res

func excl*[T](s: Set[T], key: T): Set[T]  =
  ## Deletes the `key` from the `Set`
  excl(s, hash(key))

func contains[T](node: SetNode[T], level: int, keyHash: Hash): bool  =
  if node == nil:
    # this can happen if the Set was not initialized
    return false
  let index = (keyHash shr level) and mask
  let child = node.nodes[index]
  if child == nil:
    false
  else:
    case child.kind:
    of Branch:
      contains(child, level + parazoaBits, keyHash)
    of Leaf:
      if child.keyHash == keyHash:
        true
      else:
        false

func contains[T](s: Set[T], keyHash: Hash): bool  =
  contains(s.root, 0, keyHash)

func contains*[T](s: Set[T], key: T): bool  =
  ## Returns whether `key` is inside the `Set`
  contains(s, hash(key))

iterator items*[T](s: Set[T]): T =
  ## Iterates over the values in the `Set`
  if s.root != nil:
    var stack: seq[tuple[parent: SetNode[T], index: int]] = @[(s.root, 0)]
    while stack.len > 0:
      let (parent, index) = stack[stack.len-1]
      if index == parent.nodes.len:
        discard stack.pop()
        if stack.len > 0:
          stack[stack.len-1].index += 1
      else:
        let node = parent.nodes[index]
        if node == nil:
          stack[stack.len-1].index += 1
        else:
          case node.kind:
          of Branch:
            stack.add((node, 0))
          of Leaf:
            yield node.key
            stack[stack.len-1].index += 1

func `==`*[T](s1: Set[T], s2: Set[T]): bool  =
  ## Returns whether the `Set`s are equal
  if s1.len != s2.len:
    false
  elif s1.root == s2.root:
    true
  else:
    for k in s1.items:
      if not s2.contains(k):
        return false
    true

func toSet*[T](arr: openArray[T]): Set[T] =
  ## Returns a `Set` containing the values in `arr`
  var s = initSet[T]()
  for k in arr:
    s = s.incl(k)
  s

func `$`*[T](s: Set[T]): string =
  ## Returns a string representing the `Set`
  var x = newSeq[string]()
  for k in s.items:
    x.add($k)
  "#{" & strutils.join(x, ", ") & "}"

func hash*[T](s: Set[T]): Hash  =
  ## Returns a `Hash` of the `Set`
  var h: Hash = 0
  for k in s.items:
    h = h !& hash(k)
  !$h

func `&`*[T](s1: Set[T], s2: Set[T]): Set[T] =
  ## Returns a union of the `Set`s
  var res = s1
  for k in s2.items:
    res = res.add(k)
  res

func add*[T](s1: var Set[T], s2: Set[T]) =
  ## Unites the second `Set` into the first one
  ## (This sets the var to a new `Set` -- the old `Set` is not mutated)
  s1 = s1 & s2

type
  VecNode*[T] = ref object
    case kind: NodeKind
    of Branch:
      nodes: array[branchWidth, VecNode[T]]
    of Leaf:
      value: T
  Vec*[T] = object
    root: VecNode[T]
    shift: int16
    start: int16
    size: Natural

func initVec*[T](): Vec[T]  =
  ## Returns a new `Vec`
  result.root = VecNode[T](kind: Branch)

func len*[T](v: Vec[T]): Natural =
  ## Returns the number of values in the `Vec`
  v.size

func add[T](res: var Vec[T], node: VecNode[T], level: int, key: Natural, value: T)  =
  let
    index = (key shr level) and mask
    child = node.nodes[index]
  if child == nil:
    if level == 0:
      node.nodes[index] = VecNode[T](kind: Leaf, value: value)
      res.size += 1
    else:
      let newChild = VecNode[T](kind: Branch)
      node.nodes[index] = newChild
      add(res, newChild, level - parazoaBits, key, value)
  else:
    let newChild = copyRef(child)
    case child.kind:
    of Branch:
      node.nodes[index] = newChild
      add(res, newChild, level - parazoaBits, key, value)
    of Leaf:
      newChild.value = value
      node.nodes[index] = newChild

func add*[T](v: Vec[T], key: Natural, value: T): Vec[T] =
  ## Updates the existing value at `key`
  if key < 0 or key > v.len:
    raise newException(IndexError, "Index is out of bounds")
  var res = v
  if key == v.len and key == branchWidth ^ (v.shift + 1):
    res.root = VecNode[T](kind: Branch)
    res.shift = v.shift + 1
    res.size = v.len
    let index = ((res.size-1) shr (res.shift * parazoaBits)) and mask
    res.root.nodes[index] = v.root
  else:
    res.root = copyRef(v.root)
  add(res, res.root, res.shift * parazoaBits, key, value)
  res

func add*[T](v: Vec[T], value: T): Vec[T]  =
  ## Adds a new value to the `Vec`
  add(v, v.len, value)

func del[T](res: var Vec[T], node: VecNode[T], level: int, key: Natural)  =
  let
    index = (key shr level) and mask
    child = node.nodes[index]
  if child == nil:
    discard
  else:
    case child.kind:
    of Branch:
      let newChild = copyRef(child)
      node.nodes[index] = newChild
      del(res, newChild, level + parazoaBits, key)
    of Leaf:
      node.nodes[index ..< ^2] = node.nodes[index+1 ..< ^1]
      node.nodes[^1] = nil
      res.size -= 1

func del*[T](m: Vec[T], key: Natural): Vec[T] =
  ## delete node at index
  result = m
  result.root = copyRef(m.root)
  del(result, result.root, 0, key)

func setLen*[T](v: Vec[T], newLen: Natural): Vec[T]  =
  ## Updates the length of `Vec`
  var res = v
  if v.len > newLen:
    while true:
      if res.shift > 0:
        let minSize = branchWidth ^ res.shift
        if newLen <= minSize:
          res.root = res.root.nodes[0]
          res.shift = res.shift - 1
        else:
          break
      else:
        break
    res.root = copyRef(res.root)
    res.size = newLen
    # nil out the remaining nodes
    # in case any of them have data from the larger vec
    let index = (res.size shr (res.shift * parazoaBits)) and mask
    for i in index ..< res.root.nodes.len:
      res.root.nodes[i] = nil
  elif v.len < newLen:
    while true:
      let maxSize = branchWidth ^ (res.shift + 1)
      if newLen > maxSize:
        let oldRoot = res.root
        res.root = VecNode[T](kind: Branch)
        res.shift = res.shift + 1
        let index = ((maxSize-1) shr (res.shift * parazoaBits)) and mask
        res.root.nodes[index] = oldRoot
      else:
        break
    res.root = copyRef(res.root)
    res.size = newLen
  res

func get[T](node: VecNode[T], level: int, key: Natural): T =
  if node == nil:
    # this will never happen because uninitialized Vecs
    # will produce an IndexError before it gets here
    return default(T)
  let
    index = (key shr level) and mask
    child = node.nodes[index]
  if child == nil:
    # this can happen if the vec's size was increased via setLen
    # and the value at this index was never set
    default(T)
  else:
    case child.kind:
    of Branch:
      get(child, level - parazoaBits, key)
    of Leaf:
      child.value

func get*[T](v: Vec[T], key: Natural): T =
  ## Returns the value at `key`, or raises an exception if out of bounds
  if key < 0 or key >= v.len:
    raise newException(IndexError, "Index is out of bounds")
  get(v.root, v.shift * parazoaBits, key + v.start)

func getOrDefault*[T](v: Vec[T], key: Natural, defaultValue: T): T  =
  ## Returns the value at `key`, or `defaultValue` if not found
  try:
    get(v, key)
  except IndexError:
    defaultValue

iterator pairs*[T](v: Vec[T]): (Natural, T) =
  ## Iterates over the indexes and values in the `Vec`
  if v.root != nil:
    var stack: seq[tuple[parent: VecNode[T], index: int]] = @[(v.root, v.start.int)]
    var key: Natural = 0
    while stack.len > 0:
      let (parent, index) = stack[stack.len-1]
      if index == parent.nodes.len:
        discard stack.pop()
        if stack.len > 0:
          stack[stack.len-1].index += 1
      else:
        let node = parent.nodes[index]
        if node == nil:
          break
        else:
          case node.kind:
          of Branch:
            stack.add((node, 0))
          of Leaf:
            if key >= v.size:
              break
            yield (key, node.value)
            stack[stack.len-1].index += 1
            key += 1

iterator items*[T](v: Vec[T]): T =
  ## Iterates over the values in the `Vec`
  for (i, v) in v.pairs:
    yield v

proc `[]`[T](v: Vec[T]; key: Natural): T =
  ## get key
  v.get(key)

proc `[]`[T; U, V: Ordinal](v: Vec[T]; x: HSlice[U, V]): Vec[T] =
  ## Returns the value at `key`, or raises an exception if out of bounds
  if x.a < 0 or x.a > x.b or x.b > v.size:
    raise newException(IndexError, "Index is out of bounds")
  result = v
  result.start = x.a.int16
  result.size = x.b - x.a + 1

func `==`*[T](v1: Vec[T], v2: Vec[T]): bool  =
  ## Returns whether the `Vec`s are equal
  if v1.len != v2.len:
    false
  elif v1.root == v2.root:
    true
  else:
    for (i, v) in v1.pairs:
      if v2.get(i) != v:
        return false
    true

func toVec*[T](arr: openArray[T]): Vec[T] =
  ## Returns a `Vec` containing the values in `arr`
  var v = initVec[T]()
  for k in arr:
    v = v.add(k)
  v

func toSeq*[T](v: Vec[T]): seq[T] =
  ## Returns a `seq` containing the values in `Vec`
  result = newSeqOfCap[T](v.len)
  for k in v:
    result.add(k)

func `$`*[T](v: Vec[T]): string =
  ## Returns a string representing the `Vec`
  var x = newSeq[string]()
  for k in v.items:
    x.add($k)
  "[" & strutils.join(x, ", ") & "]"

func hash*[T](v: Vec[T]): Hash  =
  ## Returns a `Hash` of the `Vec`
  var h: Hash = 0
  for k in v.items:
    h = h !& hash(k)
  !$h

func `&`*[T](v1: Vec[T], v2: Vec[T]): Vec[T] =
  ## Returns a concatenation of the `Vec`s
  var res = v1
  for k in v2.items:
    res = res.add(k)
  res

func add*[T](v1: var Vec[T], v2: Vec[T]) =
  ## Concatenates the second `Vec` into the first one
  ## (This sets the var to a new `Vec` -- the old `Vec` is not mutated)
  v1 = v1 & v2
