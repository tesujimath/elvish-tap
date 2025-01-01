#!/usr/bin/env elvish

use ./tap

# just test against canned output
var actual = (tap:run [
    [&d='simple fail' &f={ put [&ok=$false &expected=[&A=a] &actual=[&A=b]] }]
    [&d='easy pass' &f={ put [&ok=$true] }]
    [&d='skipped failure' &f={ put [&ok=$false] } &skip]
    [&d='not yet implemented' &f={ fail 'oops' } &todo]
    [&d='unexpected failure' &f={ fail 'oops' }]
    [&d='simple assertion' &f={ tap:assert $true }]
    [&d='simple assertion of expected value' &f={
      var actual = [&answer=43]
      tap:assert-expected $actual [&answer=42]
    }]
  ] | slurp)
var expected = 'TAP version 13
1..7
not ok 1 - simple fail
  ---
  actual:
    A: b
  expected:
    A: a
  ...
ok 2 - easy pass
not ok 3 - skipped failure # skip
not ok 4 - not yet implemented # todo
not ok 5 - unexpected failure
  ---
  exception:
    Content: oops
  ...
ok 6 - simple assertion
not ok 7 - simple assertion of expected value
  ---
  actual:
    answer: ''43''
  expected:
    answer: ''42''
  ...
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
