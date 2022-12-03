import unittest
import parazoa

test "maps":
  let m1 = initMap[string, string]()
  let m2 = m1.add("hello", "world")
  check m1.getOrDefault("hello", "") == ""
  check m2.getOrDefault("hello", "") == "world"
  let m3 = m1.add("hello", "goodbye")
  check m1.getOrDefault("hello", "") == ""
  check m2.getOrDefault("hello", "") == "world"
  check m3.getOrDefault("hello", "") == "goodbye"
  let m4 = m3.add("what's", "up")
  let m5 = m3.del("what's").del("asdf")
  check m5.getOrDefault("hello", "") == "goodbye"
  check m5.getOrDefault("what's", "") == ""
  check m1.size == 0
  check m2.size == 1
  check m3.size == 1
  check m4.size == 2
  check m5.size == 1

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
  check s1.size == 0
  check s2.size == 1
  check s3.size == 1
  check s4.size == 2
  check s5.size == 1

test "vecs":
  let v1 = initVec[string]()
  let v2 = v1.add("hello")
  check v1.getOrDefault(0, "") == ""
  check v2.getOrDefault(0, "") == "hello"
  let v3 = v1.add("goodbye")
  check v1.getOrDefault(0, "") == ""
  check v2.getOrDefault(0, "") == "hello"
  check v3.getOrDefault(0, "") == "goodbye"
  let v4 = v3.add("what's")
  let v5 = v3.del(0).del(10000)
  check v1.size == 0
  check v2.size == 1
  check v3.size == 1
  check v4.size == 2
  check v5.size == 1

import hashes

test "collisions":
  let m = initMap[string, string]().add(Hash(0), "hello").add(Hash(1 shl bitsPerPart), "world")
  let s = initSet[string]().incl(Hash(0)).incl(Hash(1 shl bitsPerPart))
  let v = initVec[string]().add(Hash(0), "hello").add(Hash(1 shl bitsPerPart), "world")
  check m.size == 2
  check s.size == 2
  check v.size == 2
