# elvish-tap

An early-stage implementation of [Test Anything Protocol](https://testanything.org/) (TAP) for [Elvish](https://elv.sh/),
targeting [TAP13](https://testanything.org/tap-version-13-specification.html).

## Example Usage

```
> tap:run [[&d='simple fail' &f={ put $false [&expected=[&A=a &B=b] &actual=[&A=1]]}] [&d='nothing to do' &f={ put $true }]]
TAP version 13
1..2
not ok 1 - simple fail
  ---
  actual:
    A: '1'
  expected:
    A: a
    B: b
  ...
ok 2 - nothing to do
```

In general, TAP output should be piped to a TAP consumer.

```
> tap:run [[&d='simple fail' &f={ put $false [&expected=[&A=a &B=b] &actual=[&A=1]]}] [&d='nothing to do' &f={ put $true }]] | tappy
F.
======================================================================
FAIL: <file=stream>
- simple fail
----------------------------------------------------------------------

----------------------------------------------------------------------
Ran 2 tests in 0.000s

FAILED (failures=1)
Exception: tappy exited with 1
  [tty 7]:1:126-130: tap:run [[&d='simple fail' &f={ put $false [&expected=[&A=a &B=b] &actual=[&A=1]]}] [&d='nothing to do' &f={ put $true }]] |
 tappy
```

## Tests

`tap:run` takes a list of tests.  Each test is a map

 A test comprises a map with the following keys:

 - `d` - a string, the test name or description
 - `f` - a function of no arguments, outputing one or two results.
         The first result is a boolean, $true for success
         The optional second result is a map, with the following optional fields:
         - `skip` - test is skipped,
         - `todo` - test is TODO,
         - `doc` - additional documentation map, included as a TAP YAML block.

## Dependencies

If YAML blocks are used, then `yq` is required.
