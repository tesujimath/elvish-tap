use re
use str

# TAP producer to run all the tests in a tests suite.
# Note that checking test success must be done separately, using `status`.
#
# `tests` is a list of maps, where each map is a test.
# A test comprises a map with the following keys:
# - `d` - a string, the test name or description
# - `f` - a function of no arguments, outputing the results as maps. Multiple results are possible, and correspond to TAP subtests.
#         The map has a mandatory field `ok`, a boolean, whether the test passed.  Any other fields are included as a TAP YAML block.
# - `skip` - test is skipped
# - `todo` - test is not yet implemented
#
# `d` is mandatory, and so is `f` unless `todo` is present.
fn run { |tests|
  fn validate-tests { |tests|
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

      if (has-key $test skip) {
        var skip-kind = (kind-of $test[skip])
        if (not-eq $skip-kind bool) {
          fail 'test '$i' `skip` must be bool, found '$skip-kind
        }
      }

      var todo = $false
      if (has-key $test todo) {
        var todo-kind = (kind-of $test[todo])
        if (not-eq $todo-kind bool) {
          fail 'test '$i' `todo` must be bool, found '$todo-kind
        }

        if $test[todo] {
          set todo = $true
        }
      }

      if (not (has-key $test f)) {
        if (not $todo) {
          fail 'test '$i' missing `f`'
        }
      } else {
        var f-kind = (kind-of $test[f])
        if (not-eq $f-kind fn) {
          fail 'test '$i' `f` must be fn, found '$f-kind
        }
      }
    }
  }

  fn validate-test-results { |i-test results|
    var i = 0
    for result $results {
      # number results from 1 like TAP numbers tests
      set i = (+ 1 $i)

      var result-kind = (kind-of $result)
      if (not-eq $result-kind map) {
        fail 'test '$i-test' result '$i' must be map, found '$result-kind': '(to-string $result)
      }

      if (not (has-key $result ok)) {
        fail 'test '$i-test' result '$i' missing `ok`'
      }
      var ok-kind = (kind-of $result[ok])
      if (not-eq $ok-kind bool) {
        fail 'test '$i-test' result '$i' `ok` must be bool, found '$ok-kind
      }
    }
  }

  fn write-yaml-block { |block|
    var yaml = (var ok = ?(
      put $block | to-json | yq --yaml-output --sort-keys --explicit-start --explicit-end | from-lines | {
        each { |line|
          put '  '$line
        } | put [(all)]
      }
    ))

    if $ok {
      echo (str:join "\n" $yaml)
    } else {
      echo '  --- YAML block elided because yq not found'
      echo '  ...'
    }
  }

  fn write-result { |i test result|
    var status = (if $result[ok] { put 'ok' } else { put 'not ok' })
    var directive = (
      if (and (has-key $test skip) $test[skip]) {
        put ' # skip'
      } elif (and (has-key $test todo) $test[todo]) {
        put ' # todo'
      } else {
        put ''
      }
    )
    echo $status' '$i' - '$test[d]$directive

    var yaml-block = (dissoc $result ok)
    if (not-eq [&] $yaml-block) {
      write-yaml-block $yaml-block
    }
  }

  validate-tests $tests

  echo 'TAP version 13'
  echo '1..'(count $tests)

  var i-test = 0
  for test $tests {
    # TAP numbers tests from 1
    set i-test = (+ 1 $i-test)

    if (and (has-key $test todo) $test[todo]) {
      # TODO tests are recorded as failure
      write-result $i-test $test [&ok=$false]
      continue
    }

    var results = (var f_ok = ?($test[f] | put [(all)]))
    if (not $f_ok) {
      write-result $i-test $test [&ok=$false &exception=$f_ok[reason]]
    } elif (== (count $results) 0) {
      # no results, which we interpret as todo
      write-result $i-test (assoc $test todo $true) [&ok &reason='test function wrote no result']
    } else {
      validate-test-results $i-test $results

      if (== (count $results) 1) {
          write-result $i-test $test $results[0]
      } else {
        # multiple results would be subtests in TAP14, but for TAP13 we squish them into a single test
        var all-ok = $true
        var all-results = [&]
        var i-result = 0
        for result $results {
          # number results from 1
          set i-result = (+ 1 $i-result)
          if (not $result[ok]) {
            set all-ok = $false
          }
          set all-results = (assoc $all-results $i-result $result)
        }

        var composite-description = $test[d]' ('(count $results)' results)'
        var composite-test = [&d= $composite-description]
        if $all-ok {
          write-result $i-test $composite-test [&ok=$all-ok]
        } else {
          write-result $i-test $composite-test (assoc $all-results ok $all-ok)
        }
      }
    }
  }
}

# Simple assertion of condition being $true
fn assert { |condition|
  put [&ok=$condition]
}

# Assert that the actual value is as expected
fn assert-expected { |actual expected|
  if (eq $actual $expected) {
    put [&ok]
  } else {
    put [&ok=$false &expected=$expected &actual=$actual]
  }
}

# Simple TAP consumer to check test success and format output
# Assumes valid TAP input
#
# Exits with status code 1 on test failure, unless inhibited with &exit=false
fn status { |&exit=true|
  fn find-one { |pattern source|
    { re:find &max=1 $pattern $source ; put [&] } | take 1
  }

  fn parse-line { |line|
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

  fn plural { |n|
    if (== $n 1) {
      put ''
    } else {
      put 's'
    }
  }

  var red = "\e[31m"
  var yellow = "\e[33m"
  var green = "\e[32m"
  var bold = "\e[1m"
  var normal = "\e[39;0m"

  var plan = $false
  var n-plan = 0
  var n-pass = 0
  var n-fail = 0
  var n-skip = 0
  var n-todo = 0
  var in-yaml = $false
  var bail_out = $false
  var colour = $normal

  from-lines | each { |line|
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
  set colour = (
    if (> $n-fail 0) {
      put $red
    } elif (or (> $n-skip 0) (> $n-todo 0)) {
      put $yellow
    } else {
      put $green
    }
  )
  echo
  print $bold$colour$n-plan' tests'
  if (> $n-pass 0) {
    print ', '$n-pass' passed'
  }
  if (> $n-fail 0) {
    print ', '$n-fail' failed'
  }
  if (> $n-skip 0) {
    print ', '$n-skip' skipped'
  }
  if (> $n-todo 0) {
    print ', '$n-todo' todo'
  }
  echo $normal

  var ok = (== $n-fail 0)
  if (and $exit (not $ok)) {
    exit 1
  }

  if (not $exit) {
    put $ok
  }
}

# Simple TAP consumer to check test success and format output
# Assumes valid TAP input
#
# Returns test success as a boolean
fn format {
  status &exit=$false
}
