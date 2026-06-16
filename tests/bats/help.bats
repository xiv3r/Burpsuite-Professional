#!/usr/bin/env bats

@test "help.sh shows usage and exits 0 with no args" {
    cd "${BATS_TEST_DIRNAME}/../.."
    run ./help.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Available commands"* ]]
}

@test "help.sh shows usage and exits 0 with 'help' arg" {
    cd "${BATS_TEST_DIRNAME}/../.."
    run ./help.sh help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Available commands"* ]]
}

@test "help.sh exits 1 on unknown arg" {
    cd "${BATS_TEST_DIRNAME}/../.."
    run ./help.sh unknown
    [ "$status" -eq 1 ]
}
