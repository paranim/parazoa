import hashes
from math import `^`
from strutils import nil

const
  parazoaBits* {.intdefine.} = 5
  branchWidth = 1 shl parazoaBits
  mask = branchWidth - 1
  hashSize = sizeof(Hash) * 8

type
  NodeKind = enum
    Branch,
    Leaf,

func copyRef[T](node: T): T =
  new result
  if node != nil:
    result[] = node[]

## maps

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
    size: int

func initMap*[K, V](): Map[K, V]  =
  result.root = MapNode[K, V](kind: Branch)

func len*[K, V](m: Map[K, V]): int =
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

func add*[K, V](m: Map[K, V], keyHash: Hash, key: K, value: V): Map[K, V]  =
  var res = m
  res.root = copyRef(m.root)
  var node = res.root
  add(res, node, 0, keyHash, key, value)
  res

func add*[K, V](m: Map[K, V], key: K, value: V): Map[K, V]  =
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

func del*[K, V](m: Map[K, V], keyHash: Hash): Map[K, V]  =
  var res = m
  res.root = copyRef(m.root)
  del(res, res.root, 0, keyHash)
  res

func del*[K, V](m: Map[K, V], key: K): Map[K, V] =
  del(m, hash(key))

func get[K, V](node: MapNode[K, V], level: int, keyHash: Hash): V =
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

func get*[K, V](m: Map[K, V], keyHash: Hash): V =
  get(m.root, 0, keyHash)

func get*[K, V](m: Map[K, V], key: K): V =
  get(m, hash(key))

func getOrDefault*[K, V](m: Map[K, V], key: K, default: V): V  =
  try:
    get(m, hash(key))
  except KeyError:
    default

func contains*[K, V](m: Map[K, V], key: K): bool  =
  try:
    discard get(m, key)
    true
  except KeyError:
    false

iterator pairs*[K, V](m: Map[K, V]): (K, V) =
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
  for (k, v) in m.pairs:
    yield k

iterator values*[K, V](m: Map[K, V]): V =
  for (k, v) in m.pairs:
    yield v

func `==`*[K, V](m1: Map[K, V], m2: Map[K, V]): bool  =
  if m1.len != m2.len:
    false
  elif m1.root.unsafeAddr == m2.root.unsafeAddr:
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
  var m = initMap[K, V]()
  for (k, v) in arr:
    m = m.add(k, v)
  m

func `$`*[K, V](m: Map[K, V]): string =
  var x = newSeq[string]()
  for (k, v) in m.pairs:
    x.add($k & ": " & $v)
  "{" & strutils.join(x, ", ") & "}"

func hash*[K, V](m: Map[K, V]): Hash  =
  var h: Hash = 0
  for keyVal in m.pairs:
    h = h !& hash(keyVal)
  !$h

func `&`*[K, V](m1: Map[K, V], m2: Map[K, V]): Map[K, V] =
  var res = m1
  for (k, v) in m2.pairs:
    res = res.add(k, v)
  res

func add*[K, V](m1: var Map[K, V], m2: Map[K, V]) =
  m1 = m1 & m2

## sets

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
    size: int

func initSet*[T](): Set[T]  =
  result.root = SetNode[T](kind: Branch)

func len*[T](s: Set[T]): int =
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

func incl*[T](s: Set[T], keyHash: Hash, key: T): Set[T]  =
  var res = s
  res.root = copyRef(s.root)
  incl(res, res.root, 0, keyHash, key)
  res

func incl*[T](s: Set[T], key: T): Set[T]  =
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

func excl*[T](s: Set[T], keyHash: Hash): Set[T]  =
  var res = s
  res.root = copyRef(s.root)
  excl(res, res.root, 0, keyHash)
  res

func excl*[T](s: Set[T], key: T): Set[T]  =
  excl(s, hash(key))

func contains[T](node: SetNode[T], level: int, keyHash: Hash): bool  =
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

func contains*[T](s: Set[T], keyHash: Hash): bool  =
  contains(s.root, 0, keyHash)

func contains*[T](s: Set[T], key: T): bool  =
  contains(s, hash(key))

iterator items*[T](s: Set[T]): T =
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
  if s1.len != s2.len:
    false
  elif s1.root.unsafeAddr == s2.root.unsafeAddr:
    true
  else:
    for k in s1.items:
      if not s2.contains(k):
        return false
    true

func toSet*[T](arr: openArray[T]): Set[T] =
  var s = initSet[T]()
  for k in arr:
    s = s.incl(k)
  s

func `$`*[T](s: Set[T]): string =
  var x = newSeq[string]()
  for k in s.items:
    x.add($k)
  "#{" & strutils.join(x, ", ") & "}"

func hash*[T](s: Set[T]): Hash  =
  var h: Hash = 0
  for k in s.items:
    h = h !& hash(k)
  !$h

func `&`*[T](s1: Set[T], s2: Set[T]): Set[T] =
  var res = s1
  for k in s2.items:
    res = res.add(k)
  res

func add*[T](s1: var Set[T], s2: Set[T]) =
  s1 = s1 & s2

## vecs

type
  VecNode*[T] = ref object
    case kind: NodeKind
    of Branch:
      nodes: array[branchWidth, VecNode[T]]
    of Leaf:
      value: T
  Vec*[T] = object
    root: VecNode[T]
    shift: int
    size: int

func initVec*[T](): Vec[T]  =
  result.root = VecNode[T](kind: Branch)

func len*[T](v: Vec[T]): int =
  v.size

func add[T](res: var Vec[T], node: VecNode[T], level: int, key: int, value: T)  =
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

func add*[T](v: Vec[T], key: int, value: T): Vec[T] =
  if key < 0 or key > v.len:
    raise newException(IndexDefect, "Index is out of bounds")
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
  try:
    add(v, v.len, value)
  except IndexDefect:
    v

func get[T](node: VecNode[T], level: int, key: int): T =
  let
    index = (key shr level) and mask
    child = node.nodes[index]
  if child == nil:
    raise newException(IndexDefect, "Index is out of bounds")
  else:
    case child.kind:
    of Branch:
      get(child, level - parazoaBits, key)
    of Leaf:
      return child.value

func get*[T](v: Vec[T], key: int): T =
  get(v.root, v.shift * parazoaBits, key)

func getOrDefault*[T](v: Vec[T], key: int, default: T): T  =
  try:
    get(v, key)
  except IndexDefect:
    default

iterator pairs*[T](v: Vec[T]): (int, T) =
  var stack: seq[tuple[parent: VecNode[T], index: int]] = @[(v.root, 0)]
  var key = 0
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
          yield (key, node.value)
          stack[stack.len-1].index += 1
          key += 1

iterator items*[T](v: Vec[T]): T =
  for (i, v) in v.pairs:
    yield v

func `==`*[T](v1: Vec[T], v2: Vec[T]): bool  =
  if v1.len != v2.len:
    false
  elif v1.root.unsafeAddr == v2.root.unsafeAddr:
    true
  else:
    for (i, v) in v1.pairs:
      if v2.get(i) != v:
        return false
    true

func toVec*[T](arr: openArray[T]): Vec[T] =
  var v = initVec[T]()
  for k in arr:
    v = v.add(k)
  v

func `$`*[T](v: Vec[T]): string =
  var x = newSeq[string]()
  for k in v.items:
    x.add($k)
  "[" & strutils.join(x, ", ") & "]"

func hash*[T](v: Vec[T]): Hash  =
  var h: Hash = 0
  for k in v.items:
    h = h !& hash(k)
  !$h

func `&`*[T](v1: Vec[T], v2: Vec[T]): Vec[T] =
  var res = v1
  for k in v2.items:
    res = res.add(k)
  res

func add*[T](v1: var Vec[T], v2: Vec[T]) =
  v1 = v1 & v2
