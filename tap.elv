# Run all the tests in a tests suite.
#
# `tests` is a list of maps, where each map is a test.
# A test comprises a map with the following keys:
# - `d` - a string, the test name or description
# - `f` - a function of no arguments, outputing one or two results.
#         The first result is a boolean, $true for success
#         The optional second result is  a map, ignored on success.
#         On failure, the map is converted to YAML using `yq` and included as test diagnostic.
fn run {|tests|
  echo 'TAP version 14'
  echo '1..'(count $tests)

  for test $tests {
    # TODO catch exception in test
    var result = ($test | put [(all)])
  }
}

fn validate {|tests|
  var tests-kind = (kind-of $tests)
  if (not-eq $tests-kind list) {
    fail 'tests must be list, found '$tests-kind
  }

  var i = 0
  for test $tests {
    var test-kind = (kind-of $test)
    if (not-eq $test-kind map) {
      fail 'test '$i' must be map, found '$test-kind': '$test
    }

    if (not (has-key $test d)) {
      fail 'test '$i' missing `d`'
    }
    var d-kind = (kind-of $test[d])
    if (not-eq $d-kind string) {
      fail 'test '$i' `d` must be string, found '$d-kind
    }

    if (not (has-key $test f)) {
      fail 'test '$i' missing `f`'
    }
    var f-kind = (kind-of $test[f])
    if (not-eq $f-kind fn) {
      fail 'test '$i' `f` must be fn, found '$f-kind
    }

    set i = (+ $i 1)
  }
}
