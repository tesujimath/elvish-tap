fn -validate {|tests|
  var tests-kind = (kind-of $tests)
  if (not-eq $tests-kind list) {
    fail 'tests must be list, found '$tests-kind
  }

  var i = 0
  for test $tests {
    # TAP numbers tests from 1
    set i = (+ $i 1)

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
  }
}

fn -tap-yaml {|doc|
  echo '  ---'
  keys $doc | each {|k|
    var v = $doc[$k]
    if (eq (kind-of $v string)) {
      echo '    '$k': '''$v''''
    }
  }
  echo '  ...'
}

fn -tap-result {|i d ok &doc=[&]|
  var status = (if $ok { put 'ok' } else { put 'not ok' })
  echo $status' '$i' - '$d

  if (not-eq $doc [&]) {
    -tap-yaml $doc
  }
}

fn -tap-fail {|i d &doc=[&]|
  -tap-result $i $d $false &doc=$doc
}

fn -tap-pass {|i d|
  -tap-result $i $true $d
}

# Run all the tests in a tests suite.
#
# `tests` is a list of maps, where each map is a test.
# A test comprises a map with the following keys:
# - `d` - a string, the test name or description
# - `f` - a function of no arguments, outputing one or two results.
#         The first result is a boolean, $true for success
#         The optional second result is a map, which is converted to YAML and included as a TAP YAML block.
fn run {|tests|
  -validate $tests

  echo 'TAP version 13'
  echo '1..'(count $tests)

  var i = 0
  for test $tests {
    # TAP numbers tests from 1
    set i = (+ $i 1)

    # TODO catch exception in test
    var result = ($test[f] | put [(all)])
    if (== (count $result) 0) {
      -tap-fail $i $test[d] &doc=[&reason='test function returned no status']
    } elif (> (count $result) 2) {
      -tap-fail $i $test[d] &doc=[&reason='test function returned '(count $result)' results, expected 1 or 2']
    } elif (not-eq (kind-of $result[0]) bool) {
      -tap-fail $i $test[d] &doc=[&reason='test function returned first result of type '(kind-of $result[0])', expected bool']
    } else {
      if (== (count $result) 2) {
        if (not-eq (kind-of $result[1]) map) {
          -tap-fail $i $test[d] &doc=[&reason='test function returned second result of type '(kind-of $result[1])', expected map']
        } else {
          -tap-result $i $test[d] $result[0] &doc=$result[1]
        }
      } else {
        -tap-result $i $test[d] $result[0]
      }
    }
  }
}

