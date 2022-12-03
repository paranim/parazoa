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
