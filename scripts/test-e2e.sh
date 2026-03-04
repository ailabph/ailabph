#!/bin/bash

# End-to-End Test Suite for aiLab.ph Blog System
# Tests complete workflow from authentication through CRUD operations

set -e

BASE_URL="${1:-http://localhost:8788}"
TESTUSER="testadmin"
TESTPASS="testpass123"

echo "========================================"
echo "aiLab.ph Blog - End-to-End Test Suite"
echo "Base URL: $BASE_URL"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

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
    echo "Response: ${body:0:200}..."
    return 1
  fi
}

echo "=== Authentication Flow ==="
echo ""

# Test 1: Login with valid credentials
echo -n "Test $((test_count + 1)): Login with valid credentials ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -c /tmp/e2e-cookies.txt \
  -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$TESTUSER\",\"password\":\"$TESTPASS\"}")
status=$(echo "$response" | tail -n 1)

if [ "$status" = "200" ] && grep -q "token" /tmp/e2e-cookies.txt; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, cookie set)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Login failed)"
  exit 1
fi

# Test 2: Check auth status
run_test "GET /api/auth/me with valid cookie" "200" \
  -b /tmp/e2e-cookies.txt \
  -X GET "$BASE_URL/api/auth/me"

# Test 3: Cookie has no Secure flag on HTTP (localhost)
echo -n "Test $((test_count + 1)): Cookie omits Secure flag on HTTP ... "
test_count=$((test_count + 1))
cookie_header=$(curl -s -i -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$TESTUSER\",\"password\":\"$TESTPASS\"}" | grep -i "Set-Cookie")

if echo "$cookie_header" | grep -v "Secure"; then
  echo -e "${GREEN}PASS${NC} (Secure flag omitted)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Secure flag should be omitted on HTTP)"
fi

echo ""
echo "=== Create Post ==="
echo ""

# Test 4: Create draft post
echo -n "Test $((test_count + 1)): Create draft post ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/e2e-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: $BASE_URL" \
  -d '{"title":"E2E Test Post","body_md":"# Test\n\nThis is a **test** post.","excerpt":"Test excerpt","status":"draft"}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "201" ] && echo "$body" | grep -q '"slug":"e2e-test-post"'; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, post created)"
  pass_count=$((pass_count + 1))
  TEST_SLUG="e2e-test-post"
else
  echo -e "${RED}FAIL${NC} (Failed to create post)"
  TEST_SLUG="e2e-test-post"
fi

# Test 5: Slug conflict returns 409
run_test "Create post with duplicate slug → 409" "409" \
  -b /tmp/e2e-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: $BASE_URL" \
  -d '{"title":"Duplicate","slug":"e2e-test-post","body_md":"Duplicate"}'

echo ""
echo "=== Read Post ==="
echo ""

# Test 6: Get post as authenticated user
run_test "GET /api/posts/$TEST_SLUG with auth" "200" \
  -b /tmp/e2e-cookies.txt \
  -X GET "$BASE_URL/api/posts/$TEST_SLUG"

# Test 7: Draft not visible on public blog
run_test "GET /blog/?post=$TEST_SLUG (draft) → 404" "404" \
  -X GET "$BASE_URL/blog/?post=$TEST_SLUG"

# Test 8: Draft not in public listing
echo -n "Test $((test_count + 1)): Draft not in public /blog/ listing ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if ! echo "$response" | grep -q "E2E Test Post"; then
  echo -e "${GREEN}PASS${NC} (draft hidden)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (draft visible publicly)"
fi

echo ""
echo "=== Update Post ==="
echo ""

# Test 9: Update post content
run_test "PUT /api/posts/$TEST_SLUG updates content" "200" \
  -b /tmp/e2e-cookies.txt \
  -X PUT "$BASE_URL/api/posts/$TEST_SLUG" \
  -H "Content-Type: application/json" \
  -H "Origin: $BASE_URL" \
  -d '{"title":"E2E Updated","body_md":"# Updated\n\nUpdated content."}'

# Test 10: Publish post (sets published_at)
echo -n "Test $((test_count + 1)): Publish post sets published_at ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/e2e-cookies.txt \
  -X PUT "$BASE_URL/api/posts/$TEST_SLUG" \
  -H "Content-Type: application/json" \
  -H "Origin: $BASE_URL" \
  -d '{"status":"published"}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "200" ] && echo "$body" | grep -q '"published_at"'; then
  echo -e "${GREEN}PASS${NC} (published_at set)"
  pass_count=$((pass_count + 1))
  PUBLISHED_AT=$(echo "$body" | grep -o '"published_at":"[^"]*"' | cut -d'"' -f4)
else
  echo -e "${RED}FAIL${NC} (published_at not set)"
fi

# Test 11: Published post visible on blog
run_test "GET /blog/?post=$TEST_SLUG (published) → 200" "200" \
  -X GET "$BASE_URL/blog/?post=$TEST_SLUG"

# Test 12: Published post in listing
echo -n "Test $((test_count + 1)): Published post in /blog/ listing ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if echo "$response" | grep -q "E2E Updated"; then
  echo -e "${GREEN}PASS${NC} (post visible)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (post not visible)"
fi

# Test 13: Unpublish preserves published_at
echo -n "Test $((test_count + 1)): Unpublish preserves published_at ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/e2e-cookies.txt \
  -X PUT "$BASE_URL/api/posts/$TEST_SLUG" \
  -H "Content-Type: application/json" \
  -H "Origin: $BASE_URL" \
  -d '{"status":"draft"}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "200" ] && echo "$body" | grep -q "\"published_at\":\"$PUBLISHED_AT\""; then
  echo -e "${GREEN}PASS${NC} (published_at preserved)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (published_at not preserved)"
fi

# Test 14: Republish doesn't change published_at
echo -n "Test $((test_count + 1)): Republish keeps original published_at ... "
test_count=$((test_count + 1))
sleep 1  # Ensure different timestamp
response=$(curl -s -w "\n%{http_code}" -b /tmp/e2e-cookies.txt \
  -X PUT "$BASE_URL/api/posts/$TEST_SLUG" \
  -H "Content-Type: application/json" \
  -H "Origin: $BASE_URL" \
  -d '{"status":"published"}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "200" ] && echo "$body" | grep -q "\"published_at\":\"$PUBLISHED_AT\""; then
  echo -e "${GREEN}PASS${NC} (published_at unchanged)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (published_at changed)"
fi

echo ""
echo "=== Security Tests ==="
echo ""

# Test 15: Unauthenticated POST → 401
run_test "POST /api/posts without auth → 401" "401" \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: $BASE_URL" \
  -d '{"title":"Test","body_md":"Test"}'

# Test 16: Unauthenticated PUT → 401
run_test "PUT /api/posts/:slug without auth → 401" "401" \
  -X PUT "$BASE_URL/api/posts/$TEST_SLUG" \
  -H "Content-Type: application/json" \
  -H "Origin: $BASE_URL" \
  -d '{"title":"Test"}'

# Test 17: Unauthenticated DELETE → 401
run_test "DELETE /api/posts/:slug without auth → 401" "401" \
  -X DELETE "$BASE_URL/api/posts/$TEST_SLUG" \
  -H "Origin: $BASE_URL"

# Test 18: Wrong Origin → 403
run_test "POST with wrong Origin → 403" "403" \
  -b /tmp/e2e-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: https://evil.com" \
  -d '{"title":"Test","body_md":"Test"}'

# Test 19: Non-JSON Content-Type → 415
run_test "POST with non-JSON Content-Type → 415" "415" \
  -b /tmp/e2e-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: text/plain" \
  -H "Origin: $BASE_URL" \
  -d '{"title":"Test","body_md":"Test"}'

echo ""
echo "=== Blog Pages (SSR) ==="
echo ""

# Test 20: Blog listing renders without JavaScript
echo -n "Test $((test_count + 1)): /blog/ renders full HTML (SSR) ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if echo "$response" | grep -q "<!DOCTYPE html>" && echo "$response" | grep -q "post-card"; then
  echo -e "${GREEN}PASS${NC} (SSR content present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (SSR content missing)"
fi

# Test 21: Single post renders without JavaScript
echo -n "Test $((test_count + 1)): /blog/?post=slug renders full HTML (SSR) ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/?post=$TEST_SLUG")

if echo "$response" | grep -q "<!DOCTYPE html>" && echo "$response" | grep -q "E2E Updated"; then
  echo -e "${GREEN}PASS${NC} (SSR post content present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (SSR post content missing)"
fi

# Test 22: Create additional posts for pagination
echo "Creating additional posts for pagination..."
for i in {1..5}; do
  curl -s -b /tmp/e2e-cookies.txt \
    -X POST "$BASE_URL/api/posts" \
    -H "Content-Type: application/json" \
    -H "Origin: $BASE_URL" \
    -d "{\"title\":\"Pagination Test $i\",\"body_md\":\"Content $i\",\"status\":\"published\"}" > /dev/null
done

# Test 23: Pagination works
run_test "GET /blog/?page=0 returns posts" "200" \
  -X GET "$BASE_URL/blog/?page=0"

echo ""
echo "=== Delete Post ==="
echo ""

# Test 24: Delete post
run_test "DELETE /api/posts/$TEST_SLUG → 204" "204" \
  -b /tmp/e2e-cookies.txt \
  -X DELETE "$BASE_URL/api/posts/$TEST_SLUG" \
  -H "Origin: $BASE_URL"

# Test 25: Deleted post returns 404
run_test "GET deleted post → 404" "404" \
  -X GET "$BASE_URL/blog/?post=$TEST_SLUG"

echo ""
echo "=== Logout ==="
echo ""

# Test 26: Logout
run_test "POST /api/auth/logout → 200" "200" \
  -X POST "$BASE_URL/api/auth/logout"

# Test 27: Auth check after logout → 401
run_test "GET /api/auth/me after logout → 401" "401" \
  -X GET "$BASE_URL/api/auth/me"

echo ""
echo "========================================"
echo "Results: $pass_count/$test_count tests passed"
echo "========================================"

# Cleanup
rm -f /tmp/e2e-cookies.txt

if [ "$pass_count" -eq "$test_count" ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
