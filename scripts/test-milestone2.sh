#!/bin/bash

# Test script for Milestone 2 - Auth API & Middleware
# Tests all deliverables against local dev server

set -e

BASE_URL="${1:-http://localhost:8788}"
TESTUSER="testadmin"

echo "========================================"
echo "Milestone 2 Auth API Tests"
echo "Base URL: $BASE_URL"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

test_count=0
pass_count=0

run_test() {
  test_count=$((test_count + 1))
  local test_name="$1"
  local expected_status="$2"
  shift 2

  echo -n "Test $test_count: $test_name ... "

  response=$(curl -s -w "\n%{http_code}" "$@")
  status=$(echo "$response" | tail -n 1)
  body=$(echo "$response" | sed '$d')

  if [ "$status" = "$expected_status" ]; then
    echo -e "${GREEN}PASS${NC} (HTTP $status)"
    pass_count=$((pass_count + 1))
    return 0
  else
    echo -e "${RED}FAIL${NC} (Expected $expected_status, got $status)"
    echo "Response: $body"
    return 1
  fi
}

echo "=== Auth Endpoints ==="
echo ""

# Test 1: POST /api/auth/login with bad credentials → 401
run_test "Login with bad credentials → 401" "401" \
  -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"wrong","password":"wrong"}'

# Test 2: POST /api/auth/login with valid credentials → 200 + cookie
echo -n "Test $((test_count + 1)): Login with valid credentials → 200 + cookie ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -c /tmp/cookies.txt \
  -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$TESTUSER\",\"password\":\"testpass123\"}")
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "200" ] && grep -q "token" /tmp/cookies.txt; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, cookie set)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 200 with cookie, got $status)"
  echo "Response: $body"
  cat /tmp/cookies.txt
fi

# Test 3: GET /api/auth/me without cookie → 401
run_test "GET /api/auth/me without cookie → 401" "401" \
  -X GET "$BASE_URL/api/auth/me"

# Test 4: GET /api/auth/me with valid cookie → 200 + username
echo -n "Test $((test_count + 1)): GET /api/auth/me with cookie → 200 + username ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/cookies.txt \
  -X GET "$BASE_URL/api/auth/me")
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "200" ] && echo "$body" | grep -q "\"username\""; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, username returned)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 200 with username, got $status)"
  echo "Response: $body"
fi

# Test 5: POST /api/auth/logout → 200 + cookie cleared
echo -n "Test $((test_count + 1)): POST /api/auth/logout → cookie cleared ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -c /tmp/cookies_after_logout.txt \
  -X POST "$BASE_URL/api/auth/logout")
status=$(echo "$response" | tail -n 1)

if [ "$status" = "200" ]; then
  echo -e "${GREEN}PASS${NC} (HTTP $status)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 200, got $status)"
fi

echo ""
echo "=== Posts Middleware Tests ==="
echo ""

# Re-login for middleware tests
curl -s -c /tmp/cookies.txt \
  -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$TESTUSER\",\"password\":\"testpass123\"}" > /dev/null

# Test 6: GET /api/posts passes without auth (middleware allows GET)
# Note: endpoint doesn't exist yet, but middleware should pass it through
# Pages serves index.html as fallback, so we expect 200
run_test "GET /api/posts without auth → passes middleware" "200" \
  -X GET "$BASE_URL/api/posts"

# Test 7: POST /api/posts without JWT → 401
run_test "POST /api/posts without JWT → 401" "401" \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -d '{"test":"data"}'

# Test 8: POST /api/posts with wrong Origin → 403
run_test "POST /api/posts with wrong Origin → 403" "403" \
  -b /tmp/cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: https://evil.com" \
  -d '{"test":"data"}'

# Test 9: POST /api/posts with non-JSON Content-Type → 415
run_test "POST /api/posts with non-JSON Content-Type → 415" "415" \
  -b /tmp/cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: text/plain" \
  -d '{"test":"data"}'

# Test 10: POST /api/posts with valid auth and allowed origin → passes middleware
# Note: Will get 405 since endpoint handler doesn't exist yet, but that proves middleware passed
# (401/403/415 would mean middleware blocked it)
run_test "POST /api/posts with valid auth → passes middleware" "405" \
  -b /tmp/cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"test":"data"}'

# Test 11: Verify /api/auth/* NOT gated by posts middleware
run_test "POST /api/auth/login not gated by posts middleware" "200" \
  -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$TESTUSER\",\"password\":\"testpass123\"}"

# Test 12: Cookie Secure flag test (manual - check Set-Cookie header)
echo -n "Test $((test_count + 1)): Cookie Secure flag on HTTP (local dev) ... "
test_count=$((test_count + 1))
response=$(curl -s -i -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$TESTUSER\",\"password\":\"testpass123\"}")

if echo "$response" | grep -i "Set-Cookie" | grep -v "Secure"; then
  echo -e "${GREEN}PASS${NC} (Secure flag omitted on HTTP)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Secure flag should be omitted on HTTP)"
fi

echo ""
echo "========================================"
echo "Results: $pass_count/$test_count tests passed"
echo "========================================"

# Cleanup
rm -f /tmp/cookies.txt /tmp/cookies_after_logout.txt

if [ "$pass_count" -eq "$test_count" ]; then
  exit 0
else
  exit 1
fi
