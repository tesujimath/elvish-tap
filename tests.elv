#!/usr/bin/env elvish

use ./tap

# just test against canned output
var actual = (tap:run [[&d='simple fail' &f={ put $false [&expected=[&A=a] &actual=[&A=b]]}] [&d='easy pass' &f={ put $true }]] | slurp)
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

if (not-eq $actual $expected) {
  put actual $actual expected $expected
  fail "unexpected output"
}
