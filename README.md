# elvish-tap

An implementation of [Test Anything Protocol](https://testanything.org/) (TAP) for [Elvish](https://elv.sh/),
targeting [TAP13](https://testanything.org/tap-version-13-specification.html).

<img src="https://raw.githubusercontent.com/tesujimath/elvish-tap/main/examples/images/elvish-tap-example.png" alt="Example tap:status output"/>

## Example Usage

```
> tap:run [
    [&d='unreasonable expectation' &f={
      var actual = [&A=1]
      tap:assert-expected $actual [&A=a &B=b]
    }]

    [&d='simple truth' &f={
      tap:assert $true
    }]]

TAP version 13
1..2
not ok 1 - unreasonable expectation
  ---
  actual:
    A: '1'
  expected:
    A: a
    B: b
  ...
ok 2 - simple truth
```

In general, TAP output should be piped to a TAP consumer (see below).

```
> tap:run [
         [&d='unreasonable expectation' &f={
           var actual = [&A=1]
           tap:assert-expected $actual [&A=a &B=b]
         }]

         [&d='simple truth' &f={
           tap:assert $true
         }]] | tap:status &exit=$false

✗ 1 - unreasonable expectation
  ---
  actual:
    A: '1'
  expected:
    A: a
    B: b
  ...
✓ 2 - simple truth

2 tests, 1 passed, 1 failed
▶ $false
```

## Tests

`tap:run` takes a list of tests.  Each test is a map with the following keys:

- `d` - a string, the test name or description
- `f` - a function of no arguments, outputing the results as maps. Multiple results are possible, and correspond to TAP subtests.
        The map has a mandatory field `ok`, a boolean, whether the test passed.  Any other fields are included as a TAP YAML block.
- `skip` - test is run and result is recorded but does not influence overall success
- `todo` - test is not yet implemented, and no attempt is made to invoke `f`, recoreded as failure without influencing overall success

`d` is mandatory, and so is `f` unless `todo` is present.

## Assertions

elvish-tap provides two simple assertions.

`assert` takes a boolean, and asserts truth.

`assert-expected` takes an actual value and an expected value (in that order), and asserts equality.

For example:
```
var actual = [&answer=43]
tap:assert-expected $actual [&answer=42]
```

## Dependencies

If YAML blocks are used, then `yq` is required, otherwise they are elided.

## TAP Consumer

`tap:status` is a simple TAP consumer, which formats test output and, usually, exits with 1 on test failure.

Exiting can be overridden by passing `&exit=$false`, which causes the overall result to be returned as a boolean.

## Examples

See [raw.elv](examples/raw.elv).

```
> ./examples/raw.elv
aya> ./examples/raw.elv
✓ 1 - easy pass
✗ 2 - skipped bothersome # skip
✗ 3 - multiple results (2 results)
  ---
  '1':
    ok: true
  '2':
    ok: false
  ...
✗ 4 - not yet implemented # todo
✗ 5 - simple fail
✓ 6 - pass with doc
  ---
  doc:
    state: enlightened
  ...
✗ 7 - fail with reason
  ---
  actual:
    A: b
  expected:
    A: a
  ...
✗ 8 - simple skipped fail # skip
  ---
  actual:
    A: b
  expected:
    A: a
  ...

8 tests, 2 passed, 3 failed, 2 skipped, 1 todo
▶ $false
```

### Assertions

```
tap:run [
  [&d='easy pass' &f={ assert $true }]
  [&d='simple fail' &f={ assert $false}]
  [&d='skipped bothersome' &f={ assert $false } &skip]
  [&d='multiple results' &f={ assert $true; assert $false }]
  [&d='fail expected' &f={ assert-expected [&A=b] [&A=a] }]
]
```

output is:
```
✓ 1 - easy pass
✗ 2 - simple fail
✗ 3 - skipped bothersome # skip
✗ 4 - multiple results (2 results)
  ---
  '1':
    ok: true
  '2':
    ok: false
  ...
✗ 5 - fail expected
  ---
  actual:
    A: b
  expected:
    A: a
  ...

5 tests, 1 passed, 3 failed, 1 skipped
```

## Future work

Tests producing multiple results are not yet in fact implemented as TAP subtests (requires TAP14), but simply squished together into
a single summary result.
