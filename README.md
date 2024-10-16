# elvish-tap

An early-stage implementation of [Test Anything Protocol](https://testanything.org/) (TAP) for [Elvish](https://elv.sh/).

It is being for [TAP13](https://testanything.org/tap-version-13-specification.html).

## Example Usage

```
tap:run [[&d='simple fail' &f={ put $false [&reason='oops']}] [&d='nothing to do' &f={ put $true }]]
TAP version 13
1..2
not ok 1 - simple fail
  ---
    reason: 'oops'
  ...
ok 2 - nothing to do
```

In general, TAP output should be piped to a TAP consumer.

```
> tap:run [[&d='simple fail' &f={ put $false [&reason='oops']}] [&d='nothing to do' &f={ put $true }]] | tappy
F.
======================================================================
FAIL: <file=stream>
- simple fail
----------------------------------------------------------------------

----------------------------------------------------------------------
Ran 2 tests in 0.000s

FAILED (failures=1)
Exception: tappy exited with 1
  [tty 14]:1:105-110: tap:run [[&d='simple fail' &f={ put $false [&reason='oops']}] [&d='nothing to do' &f={ put $true }]]  | tappy
```

## Dependencies

If YAML blocks are used, then `yq` is required.
