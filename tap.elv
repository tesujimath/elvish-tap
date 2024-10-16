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


# Simple TAP consumer to check test success and format output
# Assumes valid TAP input
fn status {
  fn find-one {|pattern source|
    { re:find &max=1 $pattern $source ; put [&] } | take 1
  }

  var red = "\e[31m"
  var yellow = "\e[33m"
  var green = "\e[32m"
  var normal = "\e[39m"

  var first-line = $true
  var plan = $false
  var n_plan = 0
  var n_pass = 0
  var n_fail = 0
  var n_skip = 0
  var n_todo = 0
  var in_yaml = $false
  var bail_out = $false
  var colour = $normal

  from-lines | each {|line|
    var output = $line

    if (and $first-line (str:has-prefix $line 'TAP version')) {
      # skip protocol line
      set output = $nil
    } else {
      # plan
      var m = (find-one '^1\.\.(\d+)' $line)
      if (has-key $m start) {
        set plan = $true
        set n_plan = (num $m[groups][1][text])
        set output = $nil
      } else {
        # test point
        var m = (find-one '^(not *)?ok( *(\d+))?( *-)? *([^#]*)( *# *(\w*)( *(.*))?)?$' $line)
        if (has-key $m start) {
          var ok = (eq $m[groups][1][text] '')
          var directive-type = (str:to-lower $m[groups][7][text])
          var status = (if $ok { put '✓' } else { put '✗' })
          var description = $m[groups][5][text]
          var directive = $m[groups][6][text]

          set colour = (
            if (==s $directive-type "skip") {
              put $yellow
            } elif (==s $directive-type "todo") {
              put $yellow
            } elif $ok {
              put $green
            } else {
              put $red
            }
          )
          set output = $status' '$description$directive
        } else {
          # YAML start
          var m = (find-one '^ *---' $line)
          if (has-key $m start) {
            set in_yaml = $true
          } else {
            # YAML end
            var m = (find-one '^ *\.\.\.' $line)
            if (has-key $m start) {
              set in_yaml = $false
            } else {
              # bail out
              var m = (find-one '^Bail out!' $line)
              if (has-key $m start) {
                set bail_out = $true
                set colour = $red
              } else {
                # empty
                var m = (find-one '^\s*$' $line)
                if (has-key $m start) {
                  # empty
                } elif $in_yaml {
                  # do the default thing
                } else {
                  # unsupported
                  set colour = $yellow
                }
              }
            }
          }
        }
      }
    }

    if (not-eq $output $nil) {
      echo $colour$output$normal
    }

    set first-line = $false
  }
}
