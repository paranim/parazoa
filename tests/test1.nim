import unittest
import parazoa

test "maps":
  let m1 = initMap[string, string]()
  let m2 = m1.add("hello", "world")
  check m1.get("hello", "") == ""
  check m2.get("hello", "") == "world"
  let m3 = m1.add("hello", "goodbye")
  check m1.get("hello", "") == ""
  check m2.get("hello", "") == "world"
  check m3.get("hello", "") == "goodbye"
  let m4 = m3.add("what's", "up")
  check m1.size == 0
  check m2.size == 1
  check m3.size == 1
  check m4.size == 2
