import hashes

const
  bitsPerPart = 5
  branchWidth = 1 shl bitsPerPart
  mask = branchWidth - 1
  levels = int((sizeof(Hash) * 8) / bitsPerPart) - 1

type
  NodeKind* = enum
    Leaf,
    Branch,
  Node*[K, V] = ref object
    case kind: NodeKind
    of Leaf:
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

func add*[K, V](m: Map[K, V], key: K, value: V): Map[K, V] =
  new result
  result[] = m[]
  result.root = copy(m.root)
  let h = hash(key)
  var node = result.root
  for level in countDown(levels, 1):
    let index = (h shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      if level > 1:
        nextNode = Node[K, V](kind: Branch)
      else:
        nextNode = Node[K, V](kind: Leaf)
        result.size += 1
      node.nodes[index] = nextNode
    else:
      nextNode = copy(nextNode)
    if level > 1:
      node = nextNode
    else:
      nextNode.value = value

func get*[K, V](m: Map[K, V], key: K, notFound: V): V =
  let h = hash(key)
  var node = m.root
  for level in countDown(levels, 1):
    let index = (h shr level) and mask
    var nextNode = node.nodes[index]
    if nextNode == nil:
      return notFound
    node = nextNode
  if node == nil:
    notFound
  else:
    node.value
