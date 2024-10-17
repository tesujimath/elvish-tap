use re
use str

# TAP producer to run all the tests in a tests suite.
# Note that checking test success must be done separately, using `status`.
#
# `tests` is a list of maps, where each map is a test.
# A test comprises a map with the following keys:
# - `d` - a string, the test name or description
# - `f` - a function of no arguments, outputing the results as maps. Multiple results are possible, and correspond to TAP subtests.
#         The map has the following fields, of which only `ok` is mandatory:
#
#       - `ok` - boolean, whether the test passed
#       - `skip` - test is skipped,
#       - `todo` - test is not yet implemented,
#       - `doc` - additional documentation map, included as a TAP YAML block.
fn run {|tests|
  fn validate-tests {|tests|
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

  fn validate-test-results {|results|
    var i = 0
    for result $results {
      # number results from 1 like TAP numbers tests
      set i = (+ 1 $i)

      var result-kind = (kind-of $result)
      if (not-eq $result-kind map) {
        fail 'result '$i' must be map, found '$result-kind': '(to-string $result)
      }

      if (not (has-key $result ok)) {
        fail 'result '$i' missing `ok`'
      }
      var ok-kind = (kind-of $result[ok])
      if (not-eq $ok-kind bool) {
        fail 'result '$i' `ok` must be bool, found '$ok-kind
      }

      if (has-key $result skip) {
        var skip-kind = (kind-of $result[skip])
        if (not-eq $skip-kind bool) {
          fail 'result '$i' `skip` must be bool, found '$skip-kind
        }
      }

      if (has-key $result todo) {
        var todo-kind = (kind-of $result[todo])
        if (not-eq $todo-kind bool) {
          fail 'result '$i' `todo` must be bool, found '$todo-kind
        }
      }

      if (has-key $result doc) {
        var doc-kind = (kind-of $result[doc])
        if (not-eq $doc-kind map) {
          fail 'result '$i' `doc` must be map, found '$doc-kind
        }
      }
    }
  }

  fn write-yaml-block {|doc|
    var yaml = (var ok = ?(
      put $doc | to-json | yq --yaml-output --sort-keys --explicit-start --explicit-end | from-lines | {
        each {|line|
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

  fn write-result {|i d result|
    var status = (if $result[ok] { put 'ok' } else { put 'not ok' })
    var directive = (
      if (and (has-key $result skip) $result[skip]) {
        put ' # skip'
      } elif (and (has-key $result todo) $result[todo]) {
        put ' # todo'
      } else {
        put ''
      }
    )
    echo $status' '$i' - '$d$directive

    if (has-key $result doc) {
      write-yaml-block $result[doc]
    }
  }

  fn write-fail {|i d &doc=[&]|
    write-result $i $d $false &a=[&doc=$doc]
  }

  validate-tests $tests

  echo 'TAP version 13'
  echo '1..'(count $tests)

  var i-test = 0
  for test $tests {
    # TAP numbers tests from 1
    set i-test = (+ 1 $i-test)

    # TODO catch exception in test
    var results = ($test[f] | put [(all)])
    if (== (count $results) 0) {
      write-fail $i-test $test[d] &doc=[&reason='test function returned no results']
    # } elif (> (count $results) 2) {
    #   write-fail $i-test $test[d] &doc=[&reason='test function returned '(count $results)' results, expected 1 or 2']
    # } elif (not-eq (kind-of $results[0]) bool) {
    #   write-fail $i-test $test[d] &doc=[&reason='test function returned first result of type '(kind-of $results[0])', expected bool']
    } else {
      validate-test-results $results

      if (== (count $results) 1) {
          write-result $i-test $test[d] $results[0]
      } else {
        # multiple results should be subtests, but for now squish them into a single test
        var all-ok = $true
        var all-doc = [&]
        var i-result = 0
        for result $results {
          # number results from 1
          set i-result = (+ 1 $i-result)
          if (not $result[ok]) {
            set all-ok = $false
          }
          set all-doc = (assoc $all-doc $i-result $result)
        }

        var composite-description = $test[d]' ('(count $results)' results)'
        if $all-ok {
          write-result $i-test $composite-description [&ok=$all-ok]
        } else {
          write-result $i-test $composite-description [&ok=$all-ok &doc=$all-doc]
        }

      }
    }
  }
}


# Simple TAP consumer to check test success and format output
# Assumes valid TAP input
#
# Exits with status code 1 on test failure, unless inhibited with &exit=false
fn status {|&exit=true|
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

  fn plural {|n|
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
