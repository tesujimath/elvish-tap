#!/usr/bin/env elvish

use ../tap

fn run-tests {
  tap:run [
    [&d='easy pass' &f={ put [&ok=$true] }]
    [&d='skipped bothersome' &f={ put [&ok=$false] } &skip]
    [&d='multiple results' &f={ put [&ok=$true] [&ok=$false] }]
    [&d='not yet implemented' &f={ echo "this will not run" } &todo]
    [&d='simple fail' &f={ put [&ok=$false]}]
    [&d='pass with doc' &f={ put [&ok=$true &doc=[&state=enlightened]] }]
    [&d='fail with reason' &f={ put  [&ok=$false &expected=[&A=a] &actual=[&A=b]]}]
    [&d='simple skipped fail' &f={ put  [&ok=$false &expected=[&A=a] &actual=[&A=b]]} &skip]
  ]
}

run-tests | tap:format
