# elvish-tap

An implementation of [Test Anything Protocol](https://testanything.org/) (TAP) for [Elvish](https://elv.sh/),
targeting [TAP13](https://testanything.org/tap-version-13-specification.html).

## Example Usage

```
> tap:run [
    [&d='unreasonable expectation' &f={
      var actual = [&A=1]
      tap:assert-expected $actual [&expected=[&A=a &B=b]]
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
           tap:assert-expected $actual [&expected=[&A=a &B=b]]
         }]

         [&d='simple truth' &f={
           tap:assert $true
         }]] | tap:status &exit=$false

✗ 1 - unreasonable expectation
  ---
  actual:
    A: '1'
  expected:
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
- `skip` - test is skipped
- `todo` - test is not yet implemented, and no attempt is made to invoke `f`

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

See [example.elv](examples/example.elv).

```
> ./examples/example.elv
✗ 1 - bothersome # skip
✗ 2 - easy pass (2 results)
  ---
  '1':
    ok: true
  '2':
    ok: false
  ...
✗ 3 - not yet implemented # todo
✗ 4 - simple fail
✓ 5 - easy pass
  ---
  state: enlightened
  ...
✗ 6 - simple fail # skip
  ---
  actual:
    A: b
  expected:
    A: a
  ...

6 tests, 1 passed, 2 failed, 2 skipped, 1 todo
▶ $false
```

## Future work

Tests producing multiple results are not yet in fact implemented as TAP subtests (requires TAP14), but simply squished together into
a single summary result.
