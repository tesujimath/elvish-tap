use re
use str

# TAP producer to run all the tests in a tests suite.
# Note that checking test success must be done separately, using `status`.
#
# `tests` is a list of maps, where each map is a test.
# A test comprises a map with the following keys:
# - `d` - a string, the test name or description
# - `f` - a function of no arguments, outputing one or two results.
#         The first result is a boolean, $true for success
#         The optional second result is a map, which is converted to YAML and included as a TAP YAML block.
fn run {|tests|
  fn -validate {|tests|
    var tests-kind = (kind-of $tests)
    if (not-eq $tests-kind list) {
      fail 'tests must be list, found '$tests-kind
    }

    var i = 0
    for test $tests {
      # TAP numbers tests from 1
      set i = (+ 1 $i)

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
    put $doc | to-json | yq --yaml-output --sort-keys | from-lines | each {|line|
      echo '  '$line
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

  -validate $tests

  echo 'TAP version 13'
  echo '1..'(count $tests)

  var i = 0
  for test $tests {
    # TAP numbers tests from 1
    set i = (+ 1 $i)

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


# Simple TAP consumer to check test success and format output
# Assumes valid TAP input
# Returns true if overall outcome is success
fn status {
  fn find-one {|pattern source|
    { re:find &max=1 $pattern $source ; put [&] } | take 1
  }

  fn parse-line {|line|
    if (str:has-prefix $line 'TAP version') {
      put [&type=version]
    } else {
      # plan
      var m = (find-one '^1\.\.(\d+)' $line)
      if (has-key $m start) {
        put [
          &type=plan
          &n=(num $m[groups][1][text])
        ]
      } else {
        # test point
        var m = (find-one '^(not *)?ok *((\d+)?( *-)? *([^#]*)( *# *(\w*)( *(.*))?)?)$' $line)
        if (has-key $m start) {
          var pass = (eq $m[groups][1][text] '')
          var status = (if $pass { put '✓' } else { put '✗' })
          put [
            &type=test-point
            &pass=$pass
            &directive=(str:to-lower $m[groups][7][text])
            &text=$status' '$m[groups][2][text]
          ]
        } else {
          # begin YAML
          var m = (find-one '^ *---' $line)
          if (has-key $m start) {
            put [
              &type=begin-yaml
              &text=$line
            ]
          } else {
            # end YAML
            var m = (find-one '^ *\.\.\.' $line)
            if (has-key $m start) {
              put [
                &type=end-yaml
                &text=$line
              ]
            } else {
              # bail out
              var m = (find-one '^Bail out!' $line)
              if (has-key $m start) {
                put [
                  &type=end-yaml
                  &text=$line
                ]
              } else {
                # empty
                var m = (find-one '^\s*$' $line)
                if (has-key $m start) {
                  put [
                    &type=empty
                    &text=$line
                  ]
                } else {
                  put [
                    &type=unknown
                    &text=$line
                  ]
                }
              }
            }
          }
        }
      }
    }
  }

  fn n-tests {|n|
    if (> $n 1) {
      put $n' tests'
    } else {
      put $n' test'
    }
  }

  var red = "\e[31m"
  var yellow = "\e[33m"
  var green = "\e[32m"
  var normal = "\e[39m"

  var plan = $false
  var n-plan = 0
  var n-pass = 0
  var n-fail = 0
  var n-skip = 0
  var n-todo = 0
  var in-yaml = $false
  var bail_out = $false
  var colour = $normal

  from-lines | each {|line|
    var parsed = (parse-line $line)

    if (==s plan $parsed[type]) {
      set n-plan = $parsed[n]
    } elif (==s test-point $parsed[type]) {
      set colour = (
        if (==s skip $parsed[directive]) {
          set n-skip = (+ 1 $n-skip)
          put $yellow
        } elif (==s todo $parsed[directive]) {
          set n-todo = (+ 1 $n-todo)
          put $yellow
        } elif $parsed[pass] {
          set n-pass = (+ 1 $n-pass)
          put $green
        } else {
          set n-fail = (+ 1 $n-fail)
          put $red
        }
      )
    } elif (==s begin-yaml $parsed[type]) {
      set in-yaml = $true
    } elif (==s end-yaml $parsed[type]) {
      set in-yaml = $false
    } elif (==s bail-out $parsed[type]) {
      set bail_out = $true
      set colour = $red
    } elif (and (==s unknown $parsed[type]) (not $in-yaml)) {
      set colour = $yellow
    }

    if (has-key $parsed text) {
      echo $colour$parsed[text]$normal
    }
  }

  # summary
  if (> $n-skip 0) {
    echo $yellow'warning: '(n-tests $n-skip)' skipped'$normal
  }
  if (> $n-todo 0) {
    echo $yellow'warning: '(n-tests $n-todo)' todo'$normal
  }
  if (> $n-fail 0) {
    echo $red'error: '(n-tests $n-fail)' failed'$normal
  } else {
    print $green'all tests passed'
    if (> $n-skip 0) {
      print ' or skipped'
    }
    if (> $n-todo 0) {
      print ' or todo'
    }
    echo $normal
  }

  put (== $n-fail 0)
}
