#!/usr/bin/env elvish

use ./tap

# just test against canned output
var actual = (tap:run [
    [&d='simple fail' &f={ put [&ok=$false &expected=[&A=a] &actual=[&A=b]] }]
    [&d='easy pass' &f={ put [&ok=$true] }]
    [&d='skipped failure' &f={ put [&ok=$true] } &skip]
    [&d='not yet implemented' &f={ fail 'oops' } &todo]
  ] | slurp)
var expected = 'TAP version 13
1..4
not ok 1 - simple fail
  ---
  actual:
    A: b
  expected:
    A: a
  ...
ok 2 - easy pass
ok 3 - skipped failure # skip
ok 4 - not yet implemented # todo
'

if (eq $actual $expected) {
  echo "all tests passed"
} else {
  echo ==== actual
  echo $actual
  echo ==== expected
  echo $expected
  fail "tests failed"
}
