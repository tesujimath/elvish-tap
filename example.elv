#!/usr/bin/env elvish

use ./tap

tap:run [
  [&d='bothersome' &f={ put [&ok=$false &skip] }]
  [&d='easy pass' &f={ put [&ok=$true] [&ok=$false] }]
  [&d='not yet implemented' &f={ put [&ok=$false &todo] }]
  [&d='simple fail' &f={ put [&ok=$false]}]
  [&d='easy pass' &f={ put [&ok=$true &doc=[&state=enlightened]] }]
  [&d='simple fail' &f={ put  [&ok=$false &skip &doc=[&expected=[&A=a] &actual=[&A=b]]]}]
] | tap:status &exit=$false
