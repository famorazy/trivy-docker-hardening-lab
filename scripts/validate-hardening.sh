#!/usr/bin/env bash

set -uo pipefail

container_name="${CONTAINER_NAME:-securestock-api}"
host_port="${HOST_PORT:-4001}"
failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

inspect_value() {
  sudo docker inspect "$container_name" --format "$1"
}

if ! sudo docker container inspect "$container_name" >/dev/null 2>&1; then
  echo "ERROR: Container '$container_name' does not exist." >&2
  exit 2
fi

echo "=== DOCKER HARDENING VALIDATION: $container_name ==="

health="$(inspect_value '{{.State.Health.Status}}')"
runtime_user="$(inspect_value '{{.Config.User}}')"
readonly_root="$(inspect_value '{{.HostConfig.ReadonlyRootfs}}')"
cap_drop="$(inspect_value '{{json .HostConfig.CapDrop}}')"
security_options="$(inspect_value '{{json .HostConfig.SecurityOpt}}')"
log_driver="$(inspect_value '{{.HostConfig.LogConfig.Type}}')"
log_options="$(inspect_value '{{json .HostConfig.LogConfig.Config}}')"

[[ "$health" == "healthy" ]] && pass "Docker health status is healthy." || fail "Docker health status is '$health'."
[[ "$runtime_user" == "node" ]] && pass "Application runs as the node user." || fail "Unexpected runtime user '$runtime_user'."
[[ "$readonly_root" == "true" ]] && pass "Root filesystem is configured read-only." || fail "Root filesystem is writable."
[[ "$cap_drop" == *'"ALL"'* ]] && pass "All Linux capabilities are dropped." || fail "Capability-drop configuration is incomplete: $cap_drop"
[[ "$security_options" == *"no-new-privileges"* ]] && pass "Privilege escalation is blocked." || fail "no-new-privileges is absent."
[[ "$log_driver" == "local" ]] && pass "Rotating local log driver is configured." || fail "Unexpected log driver '$log_driver'."
[[ "$log_options" == *'"max-size":"10m"'* && "$log_options" == *'"max-file":"3"'* ]] \
  && pass "Log limits are 10 MB by 3 files." \
  || fail "Unexpected log limits: $log_options"

kernel_state="$(sudo docker exec "$container_name" sh -c \
  'id; grep -E "^(CapEff|NoNewPrivs|Seccomp|Seccomp_filters):" /proc/1/status')"

printf '%s\n' "$kernel_state"

grep -q '^uid=1000(node)' <<<"$kernel_state" \
  && pass "PID 1 runs with UID 1000." \
  || fail "PID 1 is not running with the expected UID."

grep -q '^CapEff:[[:space:]]*0000000000000000$' <<<"$kernel_state" \
  && pass "Effective capability mask is zero." \
  || fail "Effective capabilities remain enabled."

grep -q '^NoNewPrivs:[[:space:]]*1$' <<<"$kernel_state" \
  && pass "NoNewPrivs is enforced by the kernel." \
  || fail "NoNewPrivs is not enforced."

grep -q '^Seccomp:[[:space:]]*2$' <<<"$kernel_state" \
  && pass "Seccomp filter mode is active." \
  || fail "Seccomp filter mode is not active."

if sudo docker exec --user 0 "$container_name" \
  sh -c 'touch /hardening-validation-test' >/dev/null 2>&1; then
  fail "Root filesystem accepted a write."
  sudo docker exec --user 0 "$container_name" \
    rm -f /hardening-validation-test >/dev/null 2>&1 || true
else
  pass "Root filesystem rejected a write attempted as UID 0."
fi

health_code="$(curl --silent --output /dev/null --write-out '%{http_code}' \
  "http://127.0.0.1:${host_port}/health")"
anonymous_code="$(curl --silent --output /dev/null --write-out '%{http_code}' \
  "http://127.0.0.1:${host_port}/inventory")"

[[ "$health_code" == "200" ]] \
  && pass "Health endpoint returned HTTP 200." \
  || fail "Health endpoint returned HTTP $health_code."

[[ "$anonymous_code" == "401" ]] \
  && pass "Protected endpoint rejected anonymous access with HTTP 401." \
  || fail "Protected endpoint returned HTTP $anonymous_code."

if [[ "$failures" -eq 0 ]]; then
  echo "RESULT: PASS - all Docker hardening checks succeeded."
  exit 0
fi

echo "RESULT: FAIL - $failures hardening check(s) failed."
exit 1

