#!/usr/bin/env bats

# Tests for lib.sh shared bash helpers.
# These tests avoid real network downloads and Burp binaries by using
# local fixtures and a tiny HTTP server.

setup() {
    TEST_DIR="$(mktemp -d)"
    cp "${BATS_TEST_DIRNAME}/../../lib.sh" "$TEST_DIR/lib.sh"
    cd "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "read_value normalizes whitespace and lowercases" {
    printf '  ABC123\n' > myfile
    source ./lib.sh
    run read_value myfile
    [ "$status" -eq 0 ]
    [ "$output" = 'abc123' ]
}

@test "read_version reads VERSION and sets bp_version" {
    printf '2026\n' > VERSION
    source ./lib.sh
    run read_version
    [ "$status" -eq 0 ]
    [ "$bp_version" = '2026' ]
}

@test "read_version fails on empty VERSION" {
    : > VERSION
    source ./lib.sh
    run read_version
    [ "$status" -ne 0 ]
}

@test "hash_sha256 produces lowercase hex" {
    printf 'hello world' > sample
    source ./lib.sh
    run hash_sha256 sample
    [ "$status" -eq 0 ]
    [ "$output" = 'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9' ]
}

@test "verify_sha256 succeeds on matching hash" {
    printf 'hello world' > sample
    source ./lib.sh
    run verify_sha256 sample 'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9'
    [ "$status" -eq 0 ]
    [[ "$output" == *"verified"* ]]
}

@test "verify_sha256 fails on mismatch" {
    printf 'hello world' > sample
    source ./lib.sh
    run verify_sha256 sample '0000000000000000000000000000000000000000000000000000000000000000'
    [ "$status" -ne 0 ]
}

@test "download_with_hash fetches a file and verifies hash" {
    python3 -m http.server 8765 >/dev/null 2>&1 &
    SERVER_PID=$!
    sleep 1

    printf 'fixture content' > fixture.txt
    expected='77832764857e8fcdce15190896ad985c913fb791dc79a17ac51729dc31755f4a'
    source ./lib.sh
    run download_with_hash "http://127.0.0.1:8765/fixture.txt" downloaded.txt "$expected"
    kill "$SERVER_PID" || true
    [ "$status" -eq 0 ]
    [ -f downloaded.txt ]
    [ "$(cat downloaded.txt)" = 'fixture content' ]
}

@test "download_with_hash fails and removes file on hash mismatch" {
    python3 -m http.server 8766 >/dev/null 2>&1 &
    SERVER_PID=$!
    sleep 1

    printf 'fixture content' > fixture.txt
    source ./lib.sh
    run download_with_hash "http://127.0.0.1:8766/fixture.txt" downloaded.txt '0000000000000000000000000000000000000000000000000000000000000000'
    kill "$SERVER_PID" || true
    [ "$status" -ne 0 ]
    [ ! -f downloaded.txt ]
}

@test "require_command succeeds for existing command" {
    source ./lib.sh
    run require_command bash
    [ "$status" -eq 0 ]
}

@test "require_command fails for missing command" {
    source ./lib.sh
    run require_command definitely-not-a-real-command-12345
    [ "$status" -ne 0 ]
}
