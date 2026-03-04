#!/bin/bash

# Test script for Milestone 5 - Admin Panel
# Tests deliverables against local dev server

set -e

BASE_URL="${1:-http://localhost:8788}"
TESTUSER="testadmin"
TESTPASS="testpass123"

echo "========================================"
echo "Milestone 5 Admin Panel Tests"
echo "Base URL: $BASE_URL"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
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
    return 1
  fi
}

echo "=== Admin Page Structure ==="
echo ""

# Test 1: Admin page loads
run_test "GET /admin/ returns HTML" "200" \
  -X GET "$BASE_URL/admin/"

# Test 2: Page contains login form
echo -n "Test $((test_count + 1)): Page contains login form ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "loginForm" && echo "$response" | grep -q "username" && echo "$response" | grep -q "password"; then
  echo -e "${GREEN}PASS${NC} (login form present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (login form missing)"
fi

# Test 3: Dashboard HTML present
echo -n "Test $((test_count + 1)): Dashboard HTML present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "id=\"dashboard\"" && echo "$response" | grep -q "Blog Admin"; then
  echo -e "${GREEN}PASS${NC} (dashboard present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (dashboard missing)"
fi

# Test 4: Satoshi font loaded
echo -n "Test $((test_count + 1)): Satoshi font loaded ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "fontshare.com" && echo "$response" | grep -q "satoshi"; then
  echo -e "${GREEN}PASS${NC} (font loaded)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (font not loaded)"
fi

# Test 5: Dark OLED design CSS
echo -n "Test $((test_count + 1)): Dark OLED design CSS ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "var(--accent)" && echo "$response" | grep -q "var(--bg-card)" && echo "$response" | grep -q "#000000"; then
  echo -e "${GREEN}PASS${NC} (design system present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (design system missing)"
fi

# Test 6: Film grain overlay
echo -n "Test $((test_count + 1)): Film grain overlay ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "body::after" && echo "$response" | grep -q "feTurbulence"; then
  echo -e "${GREEN}PASS${NC} (film grain present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (film grain missing)"
fi

# Test 7: Responsive meta viewport
echo -n "Test $((test_count + 1)): Responsive meta viewport ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "width=device-width"; then
  echo -e "${GREEN}PASS${NC} (viewport meta present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (viewport meta missing)"
fi

# Test 8: No index for robots
echo -n "Test $((test_count + 1)): Robots noindex ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "noindex"; then
  echo -e "${GREEN}PASS${NC} (noindex present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (noindex missing)"
fi

echo ""
echo "=== JavaScript Functionality ==="
echo ""

# Test 9: App object defined
echo -n "Test $((test_count + 1)): App object defined in JS ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "window.app = app" && echo "$response" | grep -q "app.init()"; then
  echo -e "${GREEN}PASS${NC} (app object defined)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (app object missing)"
fi

# Test 10: Login function present
echo -n "Test $((test_count + 1)): Login function present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "async login" || echo "$response" | grep -q "/api/auth/login"; then
  echo -e "${GREEN}PASS${NC} (login function present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (login function missing)"
fi

# Test 11: Logout function present
echo -n "Test $((test_count + 1)): Logout function present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "async logout" || echo "$response" | grep -q "/api/auth/logout"; then
  echo -e "${GREEN}PASS${NC} (logout function present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (logout function missing)"
fi

# Test 12: Load posts function
echo -n "Test $((test_count + 1)): Load posts function ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "async loadPosts" && echo "$response" | grep -q "?all=1"; then
  echo -e "${GREEN}PASS${NC} (loadPosts function present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (loadPosts function missing)"
fi

# Test 13: CRUD functions present
echo -n "Test $((test_count + 1)): CRUD functions present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "async savePost" && echo "$response" | grep -q "async deletePost" && echo "$response" | grep -q "async editPost"; then
  echo -e "${GREEN}PASS${NC} (CRUD functions present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (CRUD functions missing)"
fi

# Test 14: Markdown renderer present
echo -n "Test $((test_count + 1)): Markdown renderer present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "renderMarkdown" && echo "$response" | grep -q "processInline"; then
  echo -e "${GREEN}PASS${NC} (markdown renderer present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (markdown renderer missing)"
fi

# Test 15: Slug generator present
echo -n "Test $((test_count + 1)): Slug generator present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "slugify(text)" && echo "$response" | grep -q "updateSlug"; then
  echo -e "${GREEN}PASS${NC} (slug generator present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (slug generator missing)"
fi

# Test 16: Preview update function
echo -n "Test $((test_count + 1)): Preview update function ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "updatePreview()"; then
  echo -e "${GREEN}PASS${NC} (preview update present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (preview update missing)"
fi

# Test 17: Toast notification function
echo -n "Test $((test_count + 1)): Toast notification function ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "showToast"; then
  echo -e "${GREEN}PASS${NC} (toast function present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (toast function missing)"
fi

# Test 18: Confirmation modal
echo -n "Test $((test_count + 1)): Confirmation modal ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "confirmDelete" && echo "$response" | grep -q "modal-overlay"; then
  echo -e "${GREEN}PASS${NC} (modal present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (modal missing)"
fi

# Test 19: Status badge rendering
echo -n "Test $((test_count + 1)): Status badge rendering ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "status-badge" && echo "$response" | grep -q "draft" && echo "$response" | grep -q "published"; then
  echo -e "${GREEN}PASS${NC} (status badges present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (status badges missing)"
fi

# Test 20: Editor layout
echo -n "Test $((test_count + 1)): Editor layout present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "class=\"editor\"" && echo "$response" | grep -q "preview-panel"; then
  echo -e "${GREEN}PASS${NC} (editor layout present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (editor layout missing)"
fi

echo ""
echo "=== API Integration ==="
echo ""

# Test 21: Auth check on init
echo -n "Test $((test_count + 1)): Auth check on init ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "auth/me"; then
  echo -e "${GREEN}PASS${NC} (auth check present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (auth check missing)"
fi

# Test 22: Error handling
echo -n "Test $((test_count + 1)): Error handling present ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "catch (error)" && echo "$response" | grep -q "response.status === 401"; then
  echo -e "${GREEN}PASS${NC} (error handling present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (error handling missing)"
fi

# Test 23: 409 conflict handling
echo -n "Test $((test_count + 1)): 409 conflict handling ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "response.status === 409" && echo "$response" | grep -q "Slug already exists"; then
  echo -e "${GREEN}PASS${NC} (conflict handling present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (conflict handling missing)"
fi

# Test 24: Origin header in requests
echo -n "Test $((test_count + 1)): Origin header in API requests ... "
test_count=$((test_count + 1))
response=$(curl -s -X GET "$BASE_URL/admin/")

if echo "$response" | grep -q "'Origin': window.location.origin"; then
  echo -e "${GREEN}PASS${NC} (origin header present)"
  pass_count=$((pass_count + 1))
else
  echo -e "${RED}FAIL${NC} (origin header missing)"
fi

echo ""
echo "========================================"
echo "Results: $pass_count/$test_count tests passed"
echo "========================================"

if [ "$pass_count" -eq "$test_count" ]; then
  exit 0
else
  exit 1
fi
