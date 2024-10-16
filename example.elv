#!/usr/bin/env elvish

use ./tap

echo 'output of tap:run'
tap:run [[&d='simple fail' &f={ put $false }] [&d='easy pass' &f={ put $true }]] | tap:status

tap:run [[&d='simple fail' &f={ put $false [&expected=[&A=a] &actual=[&A=b]]}] [&d='easy pass' &f={ put $true }]] | tap:status

# echo
# echo 'made up output'
# echo 'TAP version 14
# 1..4
# ok 1 - Input file opened
# not ok 2 - First line of the input valid
# ok 3 - Read the rest of the file
# not ok 4 - Summarized correctly # TODO Not written yet
# Bail out!
# ' | tap:status

echo 'made up output'
echo 'TAP version 14
1..4
ok 1 - Input file opened
not ok 2 - First line of the input valid
  ---
  message: ''First line invalid''
  severity: fail
  data:
    got: ''Flirble''
    expect: ''Fnible''
  ...
ok 3 - Read the rest of the file
not ok 4 - Summarized correctly # TODO Not written yet
  ---
  message: "Can''t make summary yet"
  severity: todo
  ...
' | tap:status
