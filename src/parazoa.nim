import hashes
from math import `^`

const
  bitsPerPart* {.intdefine.} = 5
  branchWidth = 1 shl bitsPerPart
  mask = branchWidth - 1
  hashSize = sizeof(Hash) * 8

type
  NodeKind* = enum
    Leaf,
    Branch,

func copyRef[T](node: T): T =
  new result
  result[] = node[]

## maps

type
  MapNode*[K, V] = ref object
    case kind: NodeKind
    of Leaf:
      key: Hash
      value: V
    of Branch:
      nodes: array[branchWidth, MapNode[K, V]]
  Map*[K, V] = ref object
    root: MapNode[K, V]
    size*: int

func initMap*[K, V](): Map[K, V] {.raises: []} =
  new result
  result.root = MapNode[K, V](kind: Branch)

func add[K, V](res: Map[K, V], node: var MapNode[K, V], startLevel: int, key: Hash, value: V) {.raises: []} =
  var level = startLevel
  while level < hashSize:
    let index = (key shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      node.nodes[index] = MapNode[K, V](kind: Leaf, key: key, value: value)
      res.size += 1
      break
    else:
      case nextNode.kind:
      of Leaf:
        if nextNode.key == key:
          node.nodes[index].value = value
        else:
          res.size -= 1
          node.nodes[index] = MapNode[K, V](kind: Branch)
          add(res, node, level + bitsPerPart, nextNode.key, nextNode.value)
          add(res, node, level + bitsPerPart, key, value)
        break
      of Branch:
        nextNode = copyRef(nextNode)
        node.nodes[index] = nextNode
        node = nextNode
        level += bitsPerPart

func add*[K, V](m: Map[K, V], key: Hash, value: V): Map[K, V] {.raises: []} =
  var res = new Map[K, V]
  res[] = m[]
  res.root = copyRef(m.root)
  var node = res.root
  add(res, node, 0, key, value)
  res

func add*[K, V](m: Map[K, V], key: K, value: V): Map[K, V] {.raises: []} =
  add(m, hash(key), value)

func del[K, V](res: Map[K, V], node: var MapNode[K, V], startLevel: int, key: Hash) {.raises: []} =
  var level = startLevel
  while level < hashSize:
    let index = (key shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      break
    else:
      case nextNode.kind:
      of Leaf:
        if nextNode.key == key:
          node.nodes[index] = nil
          res.size -= 1
        break
      of Branch:
        nextNode = copyRef(nextNode)
        node.nodes[index] = nextNode
        node = nextNode
        level += bitsPerPart

func del*[K, V](m: Map[K, V], key: Hash): Map[K, V] {.raises: []} =
  var res = new Map[K, V]
  res[] = m[]
  res.root = copyRef(m.root)
  var node = res.root
  del(res, node, 0, key)
  res

func del*[K, V](m: Map[K, V], key: K): Map[K, V] =
  del(m, hash(key))

func get*[K, V](m: Map[K, V], key: Hash): V {.raises: [KeyError]} =
  var node = m.root
  var level = 0
  while level < hashSize:
    let index = (key shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      raise newException(KeyError, "Key not found")
    else:
      case nextNode.kind:
      of Leaf:
        if nextNode.key == key:
          return nextNode.value
        else:
          raise newException(KeyError, "Key not found")
      of Branch:
        node = nextNode
        level += bitsPerPart
  raise newException(KeyError, "Key not found")

func get*[K, V](m: Map[K, V], key: K): V {.raises: [KeyError]} =
  get(m, hash(key))

func getOrDefault*[K, V](m: Map[K, V], key: K, default: V): V {.raises: []} =
  try:
    get(m, hash(key))
  except KeyError:
    default

## sets

type
  SetNode*[T] = ref object
    case kind: NodeKind
    of Leaf:
      key: Hash
    of Branch:
      nodes: array[branchWidth, SetNode[T]]
  Set*[T] = ref object
    root: SetNode[T]
    size*: int

func initSet*[T](): Set[T] {.raises: []} =
  new result
  result.root = SetNode[T](kind: Branch)

func incl[T](res: Set[T], node: var SetNode[T], startLevel: int, key: Hash) {.raises: []} =
  var level = startLevel
  while level < hashSize:
    let index = (key shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      node.nodes[index] = SetNode[T](kind: Leaf, key: key)
      res.size += 1
      break
    else:
      case nextNode.kind:
      of Leaf:
        if nextNode.key == key:
          discard
        else:
          res.size -= 1
          node.nodes[index] = SetNode[T](kind: Branch)
          incl(res, node, level + bitsPerPart, nextNode.key)
          incl(res, node, level + bitsPerPart, key)
        break
      of Branch:
        nextNode = copyRef(nextNode)
        node.nodes[index] = nextNode
        node = nextNode
        level += bitsPerPart

func incl*[T](s: Set[T], key: Hash): Set[T] {.raises: []} =
  var res = new Set[T]
  res[] = s[]
  res.root = copyRef(s.root)
  var node = res.root
  incl(res, node, 0, key)
  res

func incl*[T](s: Set[T], key: T): Set[T] {.raises: []} =
  incl(s, hash(key))

func excl[T](res: Set[T], node: var SetNode[T], startLevel: int, key: Hash) {.raises: []} =
  var level = startLevel
  while level < hashSize:
    let index = (key shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      break
    else:
      case nextNode.kind:
      of Leaf:
        if nextNode.key == key:
          node.nodes[index] = nil
          res.size -= 1
        break
      of Branch:
        nextNode = copyRef(nextNode)
        node.nodes[index] = nextNode
        node = nextNode
        level += bitsPerPart

func excl*[T](s: Set[T], key: Hash): Set[T] {.raises: []} =
  var res = new Set[T]
  res[] = s[]
  res.root = copyRef(s.root)
  var node = res.root
  excl(res, node, 0, key)
  res

func excl*[T](s: Set[T], key: T): Set[T] {.raises: []} =
  excl(s, hash(key))

func contains*[T](s: Set[T], key: Hash): bool {.raises: []} =
  var node = s.root
  var level = 0
  while level < hashSize:
    let index = (key shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      return false
    else:
      case nextNode.kind:
      of Leaf:
        if nextNode.key == key:
          return true
        else:
          return false
      of Branch:
        node = nextNode
        level += bitsPerPart
  false

func contains*[T](s: Set[T], key: T): bool {.raises: []} =
  contains(s, hash(key))

## vecs

type
  VecNode*[T] = ref object
    case kind: NodeKind
    of Leaf:
      value: T
    of Branch:
      nodes: array[branchWidth, VecNode[T]]
  Vec*[T] = ref object
    root: VecNode[T]
    shift: int
    size*: int

func initVec*[T](): Vec[T] {.raises: []} =
  new result
  result.root = VecNode[T](kind: Branch)

func add[T](res: Vec[T], node: var VecNode[T], startLevel: int, key: int, value: T) {.raises: []} =
  var level = startLevel
  while level >= 0:
    let index = (key shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      if level == 0:
        node.nodes[index] = VecNode[T](kind: Leaf, value: value)
        res.size += 1
        break
      else:
        nextNode = VecNode[T](kind: Branch)
        node.nodes[index] = nextNode
        node = nextNode
        level -= bitsPerPart
    else:
      case nextNode.kind:
      of Leaf:
        node.nodes[index].value = value
        break
      of Branch:
        nextNode = copyRef(nextNode)
        node.nodes[index] = nextNode
        node = nextNode
        level -= bitsPerPart

func add*[T](v: Vec[T], key: int, value: T): Vec[T] {.raises: [IndexDefect]} =
  if key < 0 or key > v.size:
    raise newException(IndexDefect, "Index is out of bounds")
  var res = new Vec[T]
  if key == v.size and key == branchWidth ^ (v.shift + 1):
    res.root = VecNode[T](kind: Branch)
    res.shift = v.shift + 1
    res.size = v.size
    let index = ((res.size-1) shr (res.shift * bitsPerPart)) and mask
    res.root.nodes[index] = v.root
  else:
    res[] = v[]
    res.root = copyRef(v.root)
  var node = res.root
  add(res, node, res.shift * bitsPerPart, key, value)
  res

func add*[T](v: Vec[T], value: T): Vec[T] {.raises: []} =
  try:
    add(v, v.size, value)
  except IndexDefect:
    v

func get*[T](v: Vec[T], key: int): T {.raises: [IndexDefect]} =
  var node = v.root
  var level = v.shift * bitsPerPart
  while level >= 0:
    let index = (key shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      raise newException(IndexDefect, "Index is out of bounds")
    else:
      case nextNode.kind:
      of Leaf:
        return nextNode.value
      of Branch:
        node = nextNode
        level -= bitsPerPart
  raise newException(IndexDefect, "Index is out of bounds")

func getOrDefault*[T](v: Vec[T], key: int, default: T): T {.raises: []} =
  try:
    get(v, key)
  except IndexDefect:
    default
