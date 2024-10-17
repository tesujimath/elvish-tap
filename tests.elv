#!/usr/bin/env elvish

use ./tap

# just test against canned output
var actual = (tap:run [
    [&d='simple fail' &f={ put [&ok=$false &doc=[&expected=[&A=a] &actual=[&A=b]]] }]
    [&d='easy pass' &f={ put [&ok=$true] }]
  ] | slurp)
var expected = 'TAP version 13
1..2
not ok 1 - simple fail
  ---
  actual:
    A: b
  expected:
    A: a
  ...
ok 2 - easy pass
'

if (eq $actual $expected) {
  echo "all tests passed"
} else {
  put actual $actual expected $expected
  fail "tests failed"
}
