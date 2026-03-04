#!/bin/bash

# Test script for Milestone 3 - Posts CRUD API
# Tests all deliverables against local dev server

set -e

BASE_URL="${1:-http://localhost:8788}"
TESTUSER="testadmin"

echo "========================================"
echo "Milestone 3 Posts CRUD API Tests"
echo "Base URL: $BASE_URL"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
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

# Login to get auth cookie
echo "Authenticating..."
curl -s -c /tmp/m3-cookies.txt \
  -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$TESTUSER\",\"password\":\"testpass123\"}" > /dev/null

if ! grep -q "token" /tmp/m3-cookies.txt; then
  echo -e "${RED}ERROR: Failed to authenticate${NC}"
  exit 1
fi
echo -e "${GREEN}Authenticated${NC}"
echo ""

echo "=== POST /api/posts - Create Posts ==="
echo ""

# Test 1: Create post without slug (auto-generate)
echo -n "Test $((test_count + 1)): Create post without slug → auto-generates ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/m3-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"title":"My First Post!","body_md":"# Hello World\n\nThis is **bold** and this is *italic*."}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "201" ] && echo "$body" | grep -q '"slug":"my-first-post"'; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, slug auto-generated)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 201 with slug my-first-post, got $status)"
  echo "Response: $body"
fi

# Test 2: Create post with custom slug
echo -n "Test $((test_count + 1)): Create post with custom slug ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/m3-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"title":"Second Post","slug":"custom-slug","body_md":"Content here"}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "201" ] && echo "$body" | grep -q '"slug":"custom-slug"'; then
  echo -e "${GREEN}PASS${NC} (HTTP $status)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 201, got $status)"
  echo "Response: $body"
fi

# Test 3: Create post with duplicate slug → 409
run_test "Create post with duplicate slug → 409" "409" \
  -b /tmp/m3-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"title":"Another Post","slug":"custom-slug","body_md":"Content"}'

# Test 4: Create published post → sets published_at
echo -n "Test $((test_count + 1)): Create published post → sets published_at ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/m3-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"title":"Published Post","body_md":"# Published\n\nContent","status":"published"}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "201" ] && echo "$body" | grep -q '"status":"published"' && echo "$body" | grep -q '"published_at"'; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, published_at set)"
  pass_count=$((pass_count + 1))
  PUBLISHED_SLUG=$(echo "$body" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)
else
  echo -e "${RED}FAIL${NC} (Expected 201 with published_at, got $status)"
  echo "Response: $body"
fi

# Test 5: Markdown rendering with allowlisted tags
echo -n "Test $((test_count + 1)): Markdown renders to HTML (allowlisted tags) ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/m3-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"title":"Markdown Test","body_md":"# Heading\n\n**Bold** and *italic* and `code`\n\n- List item\n- Another\n\n[Link](https://example.com)"}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "201" ] && echo "$body" | grep -q '<h1>Heading</h1>' && echo "$body" | grep -q '<strong>Bold</strong>'; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, HTML rendered)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 201 with HTML, got $status)"
  echo "Response: $body"
fi

echo ""
echo "=== GET /api/posts - List Posts ==="
echo ""

# Test 6: GET /api/posts returns published posts only
echo -n "Test $((test_count + 1)): GET /api/posts returns published posts only ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/posts")
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

# Should have the published post, not the drafts
if [ "$status" = "200" ] && echo "$body" | grep -q '"status":"published"' && ! echo "$body" | grep -q '"status":"draft"'; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, only published)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 200 with only published posts, got $status)"
  echo "Response: $body"
fi

# Test 7: GET /api/posts?all=1 with auth returns all posts
echo -n "Test $((test_count + 1)): GET /api/posts?all=1 with auth returns all posts ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/m3-cookies.txt \
  -X GET "$BASE_URL/api/posts?all=1")
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "200" ] && echo "$body" | grep -q '"status":"draft"' && echo "$body" | grep -q '"status":"published"'; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, all posts returned)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 200 with all posts, got $status)"
  echo "Response: $body"
fi

# Test 8: GET /api/posts?all=1 without auth → 401
run_test "GET /api/posts?all=1 without auth → 401" "401" \
  -X GET "$BASE_URL/api/posts?all=1"

echo ""
echo "=== GET /api/posts/:slug - Single Post ==="
echo ""

# Test 9: GET /api/posts/:slug for published post
run_test "GET /api/posts/:slug for published post" "200" \
  -X GET "$BASE_URL/api/posts/$PUBLISHED_SLUG"

# Test 10: GET /api/posts/:slug for draft without auth → 404
run_test "GET /api/posts/:slug for draft without auth → 404" "404" \
  -X GET "$BASE_URL/api/posts/my-first-post"

# Test 11: GET /api/posts/:slug for draft with auth → 200
run_test "GET /api/posts/:slug for draft with auth → 200" "200" \
  -b /tmp/m3-cookies.txt \
  -X GET "$BASE_URL/api/posts/my-first-post"

# Test 12: GET /api/posts/:slug for non-existent → 404
run_test "GET /api/posts/:slug for non-existent → 404" "404" \
  -X GET "$BASE_URL/api/posts/does-not-exist"

echo ""
echo "=== PUT /api/posts/:slug - Update Post ==="
echo ""

# Test 13: PUT /api/posts/:slug updates title and body_md
echo -n "Test $((test_count + 1)): PUT updates title and re-renders body_html ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/m3-cookies.txt \
  -X PUT "$BASE_URL/api/posts/my-first-post" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"title":"Updated Title","body_md":"# Updated\n\nNew content"}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "200" ] && echo "$body" | grep -q '"title":"Updated Title"' && echo "$body" | grep -q '<h1>Updated</h1>'; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, updated)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 200 with updates, got $status)"
  echo "Response: $body"
fi

# Test 14: PUT changing status to published sets published_at
echo -n "Test $((test_count + 1)): PUT status to published sets published_at ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/m3-cookies.txt \
  -X PUT "$BASE_URL/api/posts/my-first-post" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"status":"published"}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "200" ] && echo "$body" | grep -q '"status":"published"' && echo "$body" | grep -q '"published_at"'; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, published_at set)"
  pass_count=$((pass_count + 1))
  ORIGINAL_PUBLISHED_AT=$(echo "$body" | grep -o '"published_at":"[^"]*"' | cut -d'"' -f4)
else
  echo -e "${RED}FAIL${NC} (Expected 200 with published_at, got $status)"
  echo "Response: $body"
fi

# Test 15: PUT changing status to draft keeps published_at
echo -n "Test $((test_count + 1)): PUT status to draft keeps published_at ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/m3-cookies.txt \
  -X PUT "$BASE_URL/api/posts/my-first-post" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"status":"draft"}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "200" ] && echo "$body" | grep -q '"status":"draft"' && echo "$body" | grep -q "\"published_at\":\"$ORIGINAL_PUBLISHED_AT\""; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, published_at preserved)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 200 with preserved published_at, got $status)"
  echo "Response: $body"
fi

# Test 16: PUT changing slug
echo -n "Test $((test_count + 1)): PUT changes slug ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -b /tmp/m3-cookies.txt \
  -X PUT "$BASE_URL/api/posts/custom-slug" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"slug":"renamed-slug"}')
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "200" ] && echo "$body" | grep -q '"slug":"renamed-slug"'; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, slug changed)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 200 with new slug, got $status)"
  echo "Response: $body"
fi

# Test 17: PUT with duplicate slug → 409
run_test "PUT with duplicate slug → 409" "409" \
  -b /tmp/m3-cookies.txt \
  -X PUT "$BASE_URL/api/posts/renamed-slug" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"slug":"my-first-post"}'

echo ""
echo "=== DELETE /api/posts/:slug ==="
echo ""

# Test 18: DELETE /api/posts/:slug → 204
run_test "DELETE /api/posts/:slug → 204" "204" \
  -b /tmp/m3-cookies.txt \
  -X DELETE "$BASE_URL/api/posts/renamed-slug" \
  -H "Origin: http://localhost:8788"

# Test 19: DELETE non-existent post → 404
run_test "DELETE non-existent post → 404" "404" \
  -b /tmp/m3-cookies.txt \
  -X DELETE "$BASE_URL/api/posts/does-not-exist" \
  -H "Origin: http://localhost:8788"

echo ""
echo "=== Pagination Tests ==="
echo ""

# Create multiple posts for pagination testing
echo "Creating posts for pagination test..."
for i in {1..25}; do
  curl -s -b /tmp/m3-cookies.txt \
    -X POST "$BASE_URL/api/posts" \
    -H "Content-Type: application/json" \
    -H "Origin: http://localhost:8788" \
    -d "{\"title\":\"Post $i\",\"body_md\":\"Content $i\",\"status\":\"published\"}" > /dev/null
done
echo "Created 25 posts"

# Test 20: GET /api/posts?page=0 returns first 20
echo -n "Test $((test_count + 1)): GET /api/posts?page=0 returns max 20 with hasMore ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/posts?page=0")
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

post_count=$(echo "$body" | grep -o '"slug"' | wc -l | tr -d ' ')
has_more=$(echo "$body" | grep -o '"hasMore":true')

if [ "$status" = "200" ] && [ "$post_count" -le "20" ] && [ -n "$has_more" ]; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, $post_count posts, hasMore=true)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 200 with <=20 posts and hasMore=true, got $status with $post_count posts)"
fi

# Test 21: GET /api/posts?page=1 returns second page
echo -n "Test $((test_count + 1)): GET /api/posts?page=1 returns second page ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/posts?page=1")
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

post_count=$(echo "$body" | grep -o '"slug"' | wc -l | tr -d ' ')

if [ "$status" = "200" ] && [ "$post_count" -gt "0" ]; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, $post_count posts)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 200 with posts, got $status with $post_count posts)"
fi

echo ""
echo "========================================"
echo "Results: $pass_count/$test_count tests passed"
echo "========================================"

# Cleanup
rm -f /tmp/m3-cookies.txt

if [ "$pass_count" -eq "$test_count" ]; then
  exit 0
else
  exit 1
fi
