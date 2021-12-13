#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
LANG=C

setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'

    export UNDER_TEST=0
    export TEST_MOCK_ARGV=('scripts/pre-push')

    . scripts/pre-push
}

@test "scripts/pre-push check_unstaged success test" {
    function git() {
        echo -n
    }
    export -f git

    run check_unstaged

    assert_success
    assert_output 'scripts/pre-push ✓ git unstaged changes'
}

@test "scripts/pre-push check_unstaged fail test" {
    function git() {
        echo 'changed/file'
    }
    export -f git

    run check_unstaged

    assert_failure
    assert_output 'scripts/pre-push ✗ git unstaged changes detected'
}

@test "scripts/pre-push run_pre-commit test" {
    function pre-commit() {
        if [ -z "${GITLAB_PRIVATE_TOKEN:-}" ]; then
            echo "Error"
        fi
        echo 'OK'
    }
    export -f pre-commit

    export GITLAB_PRIVATE_TOKEN='secret'
    run run_pre-commit

    assert_success
    assert_output 'OK'
}

@test "scripts/pre-push run_pre-commit with skip hook test" {
    function pre-commit() {
        if [ "${SKIP_HOOK:-}" == 'skipped-hook' ]; then
            echo 'Skipping skipped-hook'
        fi
        echo 'OK'
    }
    export -f pre-commit

    export SKIP_HOOK='skipped-hook'
    run run_pre-commit

    assert_success
    assert_line -n 0 'Skipping skipped-hook'
    assert_line -n 1 'OK'
}

@test "scripts/pre-push run_tests success test" {
    function bats() {
        echo 'OK'
    }
    export -f bats

    run run_tests

    assert_success
    assert_line -n 0 'OK'
    assert_line -n 1 'scripts/pre-push ✓ Reduced test set'
}

@test "scripts/pre-commit run_tests fail test" {
    function bats() {
        echo 'Error!'
        return 1
    }
    export -f bats

    run run_tests

    assert_failure
    assert_line -n 0 'Error!'
    assert_line -n 1 'scripts/pre-push ✗ Reduced test set failed'
}
