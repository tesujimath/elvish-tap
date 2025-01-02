#!/usr/bin/env elvish

use ../tap

fn run-tests {
  var assert~ = $tap:assert~
  var assert-expected~ = $tap:assert-expected~
  tap:run [
    [&d='easy pass' &f={ assert $true }]
    [&d='simple fail' &f={ assert $false}]
    [&d='skipped bothersome' &f={ assert $false } &skip]
    [&d='multiple results' &f={ assert $true; assert $false }]
    [&d='fail expected' &f={ assert-expected [&A=b] [&A=a] }]
  ]
}

run-tests | tap:format
