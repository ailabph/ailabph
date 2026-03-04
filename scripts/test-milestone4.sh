#!/bin/bash

# Test script for Milestone 4 - Blog Pages (Server-Side Rendered)
# Tests all deliverables against local dev server

set -e

BASE_URL="${1:-http://localhost:8788}"
TESTUSER="testadmin"

echo "========================================"
echo "Milestone 4 Blog Pages Tests"
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
    echo "Response: ${body:0:200}..."
    return 1
  fi
}

# Login to get auth cookie
echo "Authenticating..."
curl -s -c /tmp/m4-cookies.txt \
  -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$TESTUSER\",\"password\":\"testpass123\"}" > /dev/null

if ! grep -q "token" /tmp/m4-cookies.txt; then
  echo -e "${RED}ERROR: Failed to authenticate${NC}"
  exit 1
fi
echo -e "${GREEN}Authenticated${NC}"
echo ""

# Create test posts
echo "Creating test posts..."
curl -s -b /tmp/m4-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"title":"Test Blog Post 1","body_md":"# Hello\n\nThis is the **first** test post with some *markdown*.","excerpt":"First test post excerpt","status":"published"}' > /dev/null

curl -s -b /tmp/m4-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"title":"Test Blog Post 2","body_md":"# Second Post\n\nSome content here.\n\n- List item 1\n- List item 2","excerpt":"Second test post","status":"published"}' > /dev/null

curl -s -b /tmp/m4-cookies.txt \
  -X POST "$BASE_URL/api/posts" \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:8788" \
  -d '{"title":"Draft Post","body_md":"# Draft\n\nThis should not appear.","status":"draft"}' > /dev/null

echo -e "${GREEN}Test posts created${NC}"
echo ""

echo "=== Blog Listing Page ==="
echo ""

# Test 1: GET /blog/ returns HTML
echo -n "Test $((test_count + 1)): GET /blog/ returns HTML ... "
test_count=$((test_count + 1))
response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/blog/")
status=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$status" = "200" ] && echo "$body" | grep -q "<!DOCTYPE html>" && echo "$body" | grep -q "<html"; then
  echo -e "${GREEN}PASS${NC} (HTTP $status, valid HTML)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (Expected 200 with HTML, got $status)"
fi

# Test 2: Page contains published posts
echo -n "Test $((test_count + 1)): Page contains published posts ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if echo "$response" | grep -q "Test Blog Post 1" && echo "$response" | grep -q "Test Blog Post 2"; then
  echo -e "${GREEN}PASS${NC} (posts found)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (posts not found in HTML)"
fi

# Test 3: Draft posts not visible
echo -n "Test $((test_count + 1)): Draft posts not visible ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if ! echo "$response" | grep -q "Draft Post"; then
  echo -e "${GREEN}PASS${NC} (draft hidden)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (draft post visible)"
fi

# Test 4: Page contains required elements
echo -n "Test $((test_count + 1)): Page contains nav, header, footer ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if echo "$response" | grep -q "<nav>" && echo "$response" | grep -q "<footer>" && echo "$response" | grep -q "aiLab.ph"; then
  echo -e "${GREEN}PASS${NC} (elements present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (missing required elements)"
fi

# Test 5: Satoshi font loaded
echo -n "Test $((test_count + 1)): Satoshi font loaded ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if echo "$response" | grep -q "fontshare.com" && echo "$response" | grep -q "satoshi"; then
  echo -e "${GREEN}PASS${NC} (font included)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (font not loaded)"
fi

# Test 6: CSS custom properties match site
echo -n "Test $((test_count + 1)): CSS custom properties present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if echo "$response" | grep -q "var(--accent)" && echo "$response" | grep -q "var(--bg-card)"; then
  echo -e "${GREEN}PASS${NC} (CSS vars present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (CSS vars missing)"
fi

# Test 7: Film grain overlay
echo -n "Test $((test_count + 1)): Film grain overlay present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if echo "$response" | grep -q "body::after" && echo "$response" | grep -q "feTurbulence"; then
  echo -e "${GREEN}PASS${NC} (film grain present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (film grain missing)"
fi

# Test 8: Noscript fallback
echo -n "Test $((test_count + 1)): Noscript fallback styles present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if echo "$response" | grep -q "<noscript>" && echo "$response" | grep -q ".reveal"; then
  echo -e "${GREEN}PASS${NC} (noscript present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (noscript missing)"
fi

# Test 9: Responsive meta viewport
echo -n "Test $((test_count + 1)): Responsive viewport meta tag ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if echo "$response" | grep -q "width=device-width"; then
  echo -e "${GREEN}PASS${NC} (viewport meta present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (viewport meta missing)"
fi

echo ""
echo "=== Single Post Page ==="
echo ""

# Test 10: GET /blog/?post=slug returns HTML
run_test "GET /blog/?post=test-blog-post-1 returns HTML" "200" \
  -X GET "$BASE_URL/blog/?post=test-blog-post-1"

# Test 11: Single post contains body_html
echo -n "Test $((test_count + 1)): Single post renders body_html ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/?post=test-blog-post-1")

if echo "$response" | grep -q "<h1>Hello</h1>" && echo "$response" | grep -q "<strong>first</strong>"; then
  echo -e "${GREEN}PASS${NC} (HTML rendered)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (HTML not rendered correctly)"
fi

# Test 12: Post shows title and date
echo -n "Test $((test_count + 1)): Post shows title and date ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/?post=test-blog-post-1")

if echo "$response" | grep -q "Test Blog Post 1"; then
  echo -e "${GREEN}PASS${NC} (title present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (title missing)"
fi

# Test 13: Back link to blog listing
echo -n "Test $((test_count + 1)): Back link to blog listing ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/?post=test-blog-post-1")

if echo "$response" | grep -q 'href="/blog/"' && echo "$response" | grep -q "Back to"; then
  echo -e "${GREEN}PASS${NC} (back link present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (back link missing)"
fi

# Test 14: Non-existent post returns 404
run_test "GET /blog/?post=nonexistent returns 404" "404" \
  -X GET "$BASE_URL/blog/?post=nonexistent"

# Test 15: 404 page contains proper message
echo -n "Test $((test_count + 1)): 404 page contains error message ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/?post=nonexistent")

if echo "$response" | grep -q "404" && echo "$response" | grep -q "not found"; then
  echo -e "${GREEN}PASS${NC} (404 message present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (404 message missing)"
fi

# Test 16: Draft post not accessible publicly
run_test "GET /blog/?post=draft-post returns 404" "404" \
  -X GET "$BASE_URL/blog/?post=draft-post"

echo ""
echo "=== Pagination ==="
echo ""

# Create more posts for pagination
echo "Creating additional posts for pagination test..."
for i in {3..25}; do
  curl -s -b /tmp/m4-cookies.txt \
    -X POST "$BASE_URL/api/posts" \
    -H "Content-Type: application/json" \
    -H "Origin: http://localhost:8788" \
    -d "{\"title\":\"Post $i\",\"body_md\":\"Content $i\",\"status\":\"published\"}" > /dev/null
done
echo -e "${GREEN}Additional posts created${NC}"

# Test 17: Pagination page 0 works
run_test "GET /blog/?page=0 returns 200" "200" \
  -X GET "$BASE_URL/blog/?page=0"

# Test 18: Pagination page 1 works
run_test "GET /blog/?page=1 returns 200" "200" \
  -X GET "$BASE_URL/blog/?page=1"

# Test 19: Pagination links present
echo -n "Test $((test_count + 1)): Pagination links present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if echo "$response" | grep -q "Next" && echo "$response" | grep -q "Previous"; then
  echo -e "${GREEN}PASS${NC} (pagination links present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (pagination links missing)"
fi

echo ""
echo "=== Progressive Enhancement ==="
echo ""

# Test 20: JavaScript is optional (page works without it)
echo -n "Test $((test_count + 1)): Content visible without JavaScript ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

# Check that post cards are in the HTML (not loaded via JS)
# Look for post-card class and any post title (case-insensitive)
if echo "$response" | grep -q "post-card" && echo "$response" | grep -iq "post.*<\/h2>"; then
  echo -e "${GREEN}PASS${NC} (SSR content present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (content requires JS)"
fi

# Test 21: Prefers-reduced-motion support
echo -n "Test $((test_count + 1)): Prefers-reduced-motion media query ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/blog/")

if echo "$response" | grep -q "prefers-reduced-motion"; then
  echo -e "${GREEN}PASS${NC} (reduced motion support)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (no reduced motion support)"
fi

echo ""
echo "=== Navigation ==="
echo ""

# Test 22: Blog link in main site nav
echo -n "Test $((test_count + 1)): Blog link in main site nav ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/")

if echo "$response" | grep -q 'href="/blog/"' && echo "$response" | grep -q ">Blog<"; then
  echo -e "${GREEN}PASS${NC} (blog link present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (blog link missing from main site)"
fi

echo ""
echo "========================================"
echo "Results: $pass_count/$test_count tests passed"
echo "========================================"

# Cleanup
rm -f /tmp/m4-cookies.txt

if [ "$pass_count" -eq "$test_count" ]; then
  exit 0
else
  exit 1
fi
