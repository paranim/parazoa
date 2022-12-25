import unittest

include parazoa

test "maps":
  let m1 = initMap[string, string]()
  let m2 = m1.add("hello", "world")
  expect(KeyError):
    discard m1.get("hello")
  check m2.get("hello") == "world"
  check m1.getOrDefault("hello", "") == ""
  check m2.getOrDefault("hello", "") == "world"
  check m2.contains("hello")
  let m3 = m2.add("hello", "goodbye")
  expect(KeyError):
    discard m1.get("hello")
  check m2.get("hello") == "world"
  check m3.get("hello") == "goodbye"
  let m4 = m3.add("what's", "up")
  let m5 = m3.del("what's").del("asdf")
  check m5.get("hello") == "goodbye"
  expect(KeyError):
    discard m5.get("what's")
  check m1.len == 0
  check m2.len == 1
  check m3.len == 1
  check m4.len == 2
  check m5.len == 1
  check m2 == {"hello": "world"}.toMap
  # large map
  var m6 = initMap[string, string]()
  for i in 0 .. 1024:
    m6 = m6.add($i, $i)
  check m6.len == 1025
  check m6.get("1024") == "1024"
  # pairs
  var m7 = initMap[string, string]()
  for (k, v) in m6.pairs:
    m7 = m7.add(k, v)
  check m7.len == 1025
  # keys
  var m8 = initMap[string, string]()
  for k in m7.keys:
    m8 = m8.add(k, k)
  check m8.len == 1025
  # values
  var m9 = initMap[string, string]()
  for v in m8.values:
    m9 = m9.add(v, v)
  check m9.len == 1025
  # equality
  check m1 == m1
  check m1 != m2
  check m2 != m3
  check m8 == m9
  # non-initialized maps work
  var m10: Map[string, string]
  check m10.getOrDefault("hello", "") == ""
  check m10.add("hello", "world").get("hello") == "world"
  check m10 == m1

test "sets":
  let s1 = initSet[string]()
  let s2 = s1.incl("hello")
  check not s1.contains("hello")
  check s2.contains("hello")
  let s3 = s1.incl("goodbye")
  check not s1.contains("hello")
  check s2.contains("hello")
  check s3.contains("goodbye")
  let s4 = s3.incl("what's")
  let s5 = s3.excl("what's").excl("asdf")
  check s1.len == 0
  check s2.len == 1
  check s3.len == 1
  check s4.len == 2
  check s5.len == 1
  check s2 == ["hello"].toSet
  # large set
  var s6 = initSet[string]()
  for i in 0 .. 1024:
    s6 = s6.incl($i)
  check s6.len == 1025
  check s6.contains("1024")
  # items
  var s7 = initSet[string]()
  for k in s6.items:
    s7 = s7.incl(k)
  check s7.len == 1025
  # equality
  check s1 == s1
  check s1 != s2
  check s6 == s7
  # non-initialized sets work
  var s8: Set[string]
  check not s8.contains("hello")
  check s8.incl("hello").contains("hello")
  check s8 == s1

test "vecs":
  let v1 = initVec[string]()
  let v2 = v1.add("hello")
  expect(IndexError):
    discard v1.get(0)
  check v2.get(0) == "hello"
  check v1.getOrDefault(0, "") == ""
  check v2.getOrDefault(0, "") == "hello"
  let v3 = v1.add("goodbye")
  expect(IndexError):
    discard v1.get(0)
  check v2.get(0) == "hello"
  check v3.get(0) == "goodbye"
  let v4 = v3.add("what's")
  check v1.len == 0
  check v2.len == 1
  check v3.len == 1
  check v4.len == 2
  check v2 == ["hello"].toVec
  let v5 = v4.add(1, "hello")
  check v5.get(0) == "goodbye"
  check v5.get(1) == "hello"
  # large vector
  var v6 = initVec[string]()
  for i in 0 .. 1024:
    v6 = v6.add($i)
  check v6.len == 1025
  check v6.get(1024) == "1024"
  # items
  var v7 = initVec[string]()
  for v in v6.items:
    v7 = v7.add(v)
  check v7.len == 1025
  # equality
  check v1 == v1
  check v1 != v2
  check v4 != v5
  check v6 == v7
  # setLen
  check v3 == v4.setLen(v3.len)
  let v8 = v2.setLen(1025).add(1024, "foo").setLen(1024).setLen(1025)
  check v8.get(1024) == ""
  check v8.shift == 2
  check v2.setLen(32).shift == 0
  check v2.setLen(33).setLen(32).shift == 0
  check v2.setLen(33).setLen(32).setLen(33).shift == 1
  let v9 = v8.setLen(50).add(49, "foo").setLen(49).setLen(50)
  check v9.get(49) == ""
  check v9.shift == 1
  # non-initialized vecs work
  var v10: Vec[string]
  check v10.setLen(10).len == 10
  check v10.getOrDefault(0, "") == ""
  check v10.add("hello").get(0) == "hello"
  check v10 == v1

import hashes

test "partial hash collisions":
  let m = initMap[string, string]()
            .add(Hash(0), "foo", "hello")
            .add(Hash(1 shl parazoaBits), "foo", "world")
  let s = initSet[string]()
            .incl(Hash(0), "foo")
            .incl(Hash(1 shl parazoaBits), "foo")
  check m.len == 2
  check s.len == 2
