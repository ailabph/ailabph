/**
 * Allowlisted-tag-set-by-construction markdown renderer
 *
 * Supports only these tags:
 * - Headings: h1, h2, h3, h4, h5, h6
 * - Text: p, strong, em, code
 * - Blocks: pre, blockquote, hr, br
 * - Lists: ul, ol, li
 * - Links: a (with rel="noopener noreferrer")
 *
 * All other input is HTML-escaped.
 * Raw HTML in markdown source is escaped, never passed through.
 */

/**
 * HTML-escape a string
 */
function escapeHtml(text) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return text.replace(/[&<>"']/g, m => map[m]);
}

/**
 * Generate slug from text (lowercase, strip non-alnum except hyphens, max 100 chars)
 */
export function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9-]+/g, '-')  // Replace non-alphanumeric (except hyphens) with hyphens
    .replace(/-+/g, '-')            // Collapse consecutive hyphens
    .replace(/^-+|-+$/g, '')        // Trim leading/trailing hyphens
    .substring(0, 100);              // Max 100 chars
}

/**
 * Render markdown to HTML
 * @param {string} markdown - Markdown source
 * @returns {string} - HTML output (only allowlisted tags)
 */
export function renderMarkdown(markdown) {
  if (!markdown) return '';

  const lines = markdown.split('\n');
  const html = [];
  let inCodeBlock = false;
  let codeBlockContent = [];
  let inList = null; // 'ul' or 'ol'
  let listItems = [];

  function closeList() {
    if (inList) {
      html.push(`<${inList}>`);
      html.push(listItems.join(''));
      html.push(`</${inList}>`);
      inList = null;
      listItems = [];
    }
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Code blocks (```)
    if (line.trim().startsWith('```')) {
      if (inCodeBlock) {
        // Close code block
        html.push('<pre><code>');
        html.push(escapeHtml(codeBlockContent.join('\n')));
        html.push('</code></pre>');
        codeBlockContent = [];
        inCodeBlock = false;
      } else {
        // Open code block
        closeList();
        inCodeBlock = true;
      }
      continue;
    }

    if (inCodeBlock) {
      codeBlockContent.push(line);
      continue;
    }

    // Skip empty lines
    if (line.trim() === '') {
      closeList();
      continue;
    }

    // Headings (# - ######)
    const headingMatch = line.match(/^(#{1,6})\s+(.+)$/);
    if (headingMatch) {
      closeList();
      const level = headingMatch[1].length;
      const text = processInline(headingMatch[2]);
      html.push(`<h${level}>${text}</h${level}>`);
      continue;
    }

    // Horizontal rule (---, ***, ___)
    if (line.match(/^(\*{3,}|-{3,}|_{3,})$/)) {
      closeList();
      html.push('<hr>');
      continue;
    }

    // Unordered list (-, *, +)
    const ulMatch = line.match(/^[-*+]\s+(.+)$/);
    if (ulMatch) {
      if (inList !== 'ul') {
        closeList();
        inList = 'ul';
      }
      listItems.push(`<li>${processInline(ulMatch[1])}</li>`);
      continue;
    }

    // Ordered list (1., 2., etc.)
    const olMatch = line.match(/^\d+\.\s+(.+)$/);
    if (olMatch) {
      if (inList !== 'ol') {
        closeList();
        inList = 'ol';
      }
      listItems.push(`<li>${processInline(olMatch[1])}</li>`);
      continue;
    }

    // Blockquote (>)
    const quoteMatch = line.match(/^>\s+(.+)$/);
    if (quoteMatch) {
      closeList();
      html.push(`<blockquote>${processInline(quoteMatch[1])}</blockquote>`);
      continue;
    }

    // Paragraph (default)
    closeList();
    html.push(`<p>${processInline(line)}</p>`);
  }

  // Close any remaining code block or list
  if (inCodeBlock) {
    html.push('<pre><code>');
    html.push(escapeHtml(codeBlockContent.join('\n')));
    html.push('</code></pre>');
  }
  closeList();

  return html.join('');
}

/**
 * Process inline markdown (bold, italic, code, links)
 */
function processInline(text) {
  // Escape HTML first
  text = escapeHtml(text);

  // Links: [text](url)
  text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (match, linkText, url) => {
    // Re-escape URL to prevent injection
    const safeUrl = url.replace(/"/g, '&quot;');
    return `<a href="${safeUrl}" rel="noopener noreferrer">${linkText}</a>`;
  });

  // Bold: **text** or __text__
  text = text.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
  text = text.replace(/__(.+?)__/g, '<strong>$1</strong>');

  // Italic: *text* or _text_ (but not in URLs or already processed)
  text = text.replace(/(?<![*_])\*([^*]+)\*(?![*_])/g, '<em>$1</em>');
  text = text.replace(/(?<![*_])_([^_]+)_(?![*_])/g, '<em>$1</em>');

  // Inline code: `code`
  text = text.replace(/`([^`]+)`/g, '<code>$1</code>');

  // Line breaks: double space + newline
  text = text.replace(/  \n/g, '<br>');

  return text;
}
