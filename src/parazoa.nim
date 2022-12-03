import hashes

const
  bitsPerPart = 5
  branchWidth = 1 shl bitsPerPart
  mask = branchWidth - 1
  hashSize = sizeof(Hash) * 8

type
  NodeKind* = enum
    Leaf,
    Branch,
  Node*[K, V] = ref object
    case kind: NodeKind
    of Leaf:
      key: Hash
      value: V
    of Branch:
      nodes: array[branchWidth, Node[K, V]]
  Map*[K, V] = ref object
    root: Node[K, V]
    size*: int

func initMap*[K, V](): Map[K, V] =
  new result
  result.root = Node[K, V](kind: Branch)

func copy*[K, V](node: Node[K, V]): Node[K, V] =
  new result
  result[] = node[]

func add[K, V](res: Map[K, V], node: var Node[K, V], startLevel: int, key: Hash, value: V) =
  var level = startLevel
  while level < hashSize:
    let index = (key shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      node.nodes[index] = Node[K, V](kind: Leaf, key: key, value: value)
      res.size += 1
      break
    else:
      case nextNode.kind:
      of Leaf:
        if nextNode.key == key:
          node.nodes[index].value = value
        else:
          res.size -= 1
          node.nodes[index] = Node[K, V](kind: Branch)
          add(res, node, level + bitsPerPart, nextNode.key, nextNode.value)
          add(res, node, level + bitsPerPart, key, value)
        break
      of Branch:
        nextNode = copy(nextNode)
        node.nodes[index] = nextNode
        node = nextNode
        level += bitsPerPart

func add*[K, V](m: Map[K, V], key: Hash, value: V): Map[K, V] =
  var res = new Map[K, V]
  res[] = m[]
  res.root = copy(m.root)
  var node = res.root
  add(res, node, bitsPerPart, key, value)
  res

func add*[K, V](m: Map[K, V], key: K, value: V): Map[K, V] =
  add(m, hash(key), value)

func del[K, V](res: Map[K, V], node: var Node[K, V], startLevel: int, key: Hash) =
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
        nextNode = copy(nextNode)
        node.nodes[index] = nextNode
        node = nextNode
        level += bitsPerPart

func del*[K, V](m: Map[K, V], key: Hash): Map[K, V] =
  var res = new Map[K, V]
  res[] = m[]
  res.root = copy(m.root)
  var node = res.root
  del(res, node, bitsPerPart, key)
  res

func del*[K, V](m: Map[K, V], key: K): Map[K, V] =
  del(m, hash(key))

func get*[K, V](m: Map[K, V], key: Hash, notFound: V): V =
  var node = m.root
  var level = bitsPerPart
  while level < hashSize:
    let index = (key shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      return notFound
    else:
      case nextNode.kind:
      of Leaf:
        if nextNode.key == key:
          return nextNode.value
        else:
          return notFound
      of Branch:
        node = nextNode
        level += bitsPerPart
  notFound

func get*[K, V](m: Map[K, V], key: K, notFound: V): V =
  get(m, hash(key), notFound)
