#!/usr/bin/env node

/**
 * Test markdown renderer
 */

import { renderMarkdown, slugify } from '../functions/lib/markdown.js';

console.log('Testing Markdown Renderer');
console.log('=========================\n');

// Test 1: Slug generation
console.log('Test 1: Slug generation');
console.log('Input: "My First Post!"');
console.log('Output:', slugify('My First Post!'));
console.log('Expected: my-first-post');
console.log('Match:', slugify('My First Post!') === 'my-first-post' ? '✓' : '✗');
console.log();

// Test 2: HTML escaping (no raw HTML passthrough)
console.log('Test 2: HTML escaping (security)');
const htmlInput = '<script>alert("xss")</script>\n\n**Bold**';
const htmlOutput = renderMarkdown(htmlInput);
console.log('Input:', htmlInput);
console.log('Output:', htmlOutput);
console.log('Contains <script>:', htmlOutput.includes('<script>') ? '✗ FAIL' : '✓ PASS');
console.log('Contains &lt;script&gt;:', htmlOutput.includes('&lt;script&gt;') ? '✓ PASS' : '✗ FAIL');
console.log();

// Test 3: Allowlisted tags
console.log('Test 3: Allowlisted tags');
const markdown = `# Heading 1
## Heading 2

This is **bold** and this is *italic* and this is \`code\`.

- List item 1
- List item 2

1. Ordered 1
2. Ordered 2

> Blockquote

[Link](https://example.com)

---

\`\`\`
Code block
\`\`\`
`;

const html = renderMarkdown(markdown);
console.log('Input:\n', markdown);
console.log('\nOutput:\n', html);
console.log();

// Verify tags
const checks = [
  ['<h1>', html.includes('<h1>Heading 1</h1>')],
  ['<h2>', html.includes('<h2>Heading 2</h2>')],
  ['<strong>', html.includes('<strong>bold</strong>')],
  ['<em>', html.includes('<em>italic</em>')],
  ['<code>', html.includes('<code>code</code>')],
  ['<ul>', html.includes('<ul>')],
  ['<li>', html.includes('<li>')],
  ['<ol>', html.includes('<ol>')],
  ['<blockquote>', html.includes('<blockquote>')],
  ['<a>', html.includes('<a href="https://example.com"')],
  ['rel="noopener noreferrer"', html.includes('rel="noopener noreferrer"')],
  ['<hr>', html.includes('<hr>')],
  ['<pre><code>', html.includes('<pre><code>Code block</code></pre>')],
];

console.log('Tag checks:');
checks.forEach(([tag, pass]) => {
  console.log(`  ${tag}: ${pass ? '✓' : '✗'}`);
});

console.log();
console.log('All tests:', checks.every(c => c[1]) ? '✓ PASSED' : '✗ FAILED');
