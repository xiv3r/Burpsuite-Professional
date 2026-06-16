#!/usr/bin/env bats

@test "update.sh fails cleanly when install dir is missing" {
    cd "${BATS_TEST_DIRNAME}/../.."
    run env HOME=/nonexistent ./update.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"not a git checkout"* ]]
}
