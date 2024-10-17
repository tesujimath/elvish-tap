#!/usr/bin/env elvish

use ./tap

tap:run [
  [&d='bothersome' &f={ put $false [&skip] }]
  [&d='easy pass' &f={ put $true }]
  [&d='not yet implemented' &f={ put $false [&todo] }]
  [&d='simple fail' &f={ put $false}]
  [&d='easy pass' &f={ put $true [&doc=enlightening] }]
  [&d='simple fail' &f={ put $false [&skip &doc=[&expected=[&A=a] &actual=[&A=b]]]}]
] | tap:status &exit=$false
