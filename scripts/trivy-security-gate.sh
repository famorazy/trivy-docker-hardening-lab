#!/usr/bin/env bash

set -uo pipefail

baseline_image="${BASELINE_IMAGE:-securestock-oauth-api:1.0.0}"
candidate_image="${CANDIDATE_IMAGE:-securestock-oauth-api:1.0.1}"

if ! command -v trivy >/dev/null 2>&1; then
  echo "ERROR: Trivy is not installed or is not available in PATH." >&2
  exit 2
fi

echo "=== TRIVY HIGH/CRITICAL SECURITY GATE ==="

if sudo trivy image --quiet --image-src docker \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  "$baseline_image" >/dev/null; then
  baseline_exit=0
else
  baseline_exit=$?
fi

if sudo trivy image --quiet --image-src docker \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  "$candidate_image" >/dev/null; then
  candidate_exit=0
else
  candidate_exit=$?
fi

echo "Baseline 1.0.0 exit code: $baseline_exit"
echo "Candidate 1.0.1 exit code: $candidate_exit"

if (( baseline_exit > 1 || candidate_exit > 1 )); then
  echo "RESULT: ERROR - Trivy failed to complete one or both scans."
  exit 2
fi

if [[ "$baseline_exit" -eq 1 && "$candidate_exit" -eq 0 ]]; then
  echo "RESULT: PASS - vulnerable baseline rejected; remediated candidate accepted."
  exit 0
fi

echo "RESULT: REVIEW REQUIRED - results did not match the expected 1-to-0 transition."
exit 1

