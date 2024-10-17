# elvish-tap

An implementation of [Test Anything Protocol](https://testanything.org/) (TAP) for [Elvish](https://elv.sh/),
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

In general, TAP output should be piped to a TAP consumer (see below).

```
> tap:run [[&d='simple fail' &f={ put $false [&expected=[&A=a &B=b] &actual=[&A=1]]}] [&d='nothing to do' &f={ put $true }]] | tap:status &exit=$false
✗ 1 - simple fail
✓ 2 - nothing to do

2 tests, 1 passed, 1 failed
▶ $false
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

If YAML blocks are used, then `yq` is required, otherwise they are elided.

## TAP Consumer

`tap:status` is a simple TAP consumer, which formats test output and, usually, exits with 1 on test failure.

Exiting can be overridden by passind `&exit=$false`, which causes the overall result to be returned as a boolean.
