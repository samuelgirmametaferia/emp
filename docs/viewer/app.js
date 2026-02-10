/* Minimal, self-contained Markdown renderer.
   Supported:
   - Headings (#, ##, ###)
   - Fenced code blocks (```)
   - Inline code (`code`)
   - Unordered lists (- item)
   - Ordered lists (1. item)
   - Blockquotes (> ...)
   - Links [text](url)
*/

function escapeHtml(s) {
  return s
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function renderInline(text) {
  // links
  text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_, label, url) => {
    const safeUrl = escapeHtml(url);
    const safeLabel = escapeHtml(label);
    // Keep hash-links inside the SPA.
    if (safeUrl.startsWith("#")) {
      return `<a href="${safeUrl}">${safeLabel}</a>`;
    }
    return `<a href="${safeUrl}" target="_blank" rel="noreferrer">${safeLabel}</a>`;
  });

  // inline code
  text = text.replace(/`([^`]+)`/g, (_, code) => `<code>${escapeHtml(code)}</code>`);
  return text;
}

function renderMarkdown(md) {
  const lines = md.replaceAll("\r\n", "\n").split("\n");
  let html = "";
  let inCode = false;
  let codeFenceLang = "";
  let codeLines = [];
  let inUl = false;
  let inOl = false;

  function closeLists() {
    if (inUl) { html += "</ul>"; inUl = false; }
    if (inOl) { html += "</ol>"; inOl = false; }
  }

  for (const rawLine of lines) {
    const line = rawLine;

    if (line.startsWith("```")) {
      if (!inCode) {
        closeLists();
        inCode = true;
        codeFenceLang = line.slice(3).trim();
        codeLines = [];
      } else {
        inCode = false;
        const code = escapeHtml(codeLines.join("\n"));
        const langAttr = codeFenceLang ? ` data-lang="${escapeHtml(codeFenceLang)}"` : "";
        html += `<pre${langAttr}><code>${code}</code></pre>`;
        codeFenceLang = "";
        codeLines = [];
      }
      continue;
    }

    if (inCode) {
      codeLines.push(line);
      continue;
    }

    // headings
    if (line.startsWith("# ")) { closeLists(); html += `<h1>${renderInline(escapeHtml(line.slice(2)))}</h1>`; continue; }
    if (line.startsWith("## ")) { closeLists(); html += `<h2>${renderInline(escapeHtml(line.slice(3)))}</h2>`; continue; }
    if (line.startsWith("### ")) { closeLists(); html += `<h3>${renderInline(escapeHtml(line.slice(4)))}</h3>`; continue; }

    // blockquote
    if (line.startsWith("> ")) {
      closeLists();
      html += `<blockquote>${renderInline(escapeHtml(line.slice(2)))}</blockquote>`;
      continue;
    }

    // unordered list
    if (line.startsWith("- ")) {
      if (inOl) { html += "</ol>"; inOl = false; }
      if (!inUl) { html += "<ul>"; inUl = true; }
      html += `<li>${renderInline(escapeHtml(line.slice(2)))}</li>`;
      continue;
    }

    // ordered list
    const olMatch = line.match(/^\d+\.\s+(.*)$/);
    if (olMatch) {
      if (inUl) { html += "</ul>"; inUl = false; }
      if (!inOl) { html += "<ol>"; inOl = true; }
      html += `<li>${renderInline(escapeHtml(olMatch[1]))}</li>`;
      continue;
    }

    // blank line
    if (line.trim() === "") {
      closeLists();
      continue;
    }

    // paragraph
    closeLists();
    html += `<p>${renderInline(escapeHtml(line))}</p>`;
  }

  if (inCode) {
    const code = escapeHtml(codeLines.join("\n"));
    html += `<pre><code>${code}</code></pre>`;
  }

  if (inUl) html += "</ul>";
  if (inOl) html += "</ol>";
  return html;
}

async function loadManifest() {
  // Use an absolute path so the viewer works whether opened as:
  //   /docs/viewer/  or  /docs/viewer/index.html  or  /docs/viewer
  // Some servers treat /docs/viewer as a file (no trailing slash), which breaks relative URLs.
  const res = await fetch("/docs/manifest.json", { cache: "no-store" });
  if (!res.ok) throw new Error(`Failed to load manifest: ${res.status}`);
  return await res.json();
}

function setStatus(text) {
  document.getElementById("status").textContent = text;
}

function setActiveLink(path) {
  for (const a of document.querySelectorAll("#nav a")) {
    a.classList.toggle("active", a.getAttribute("data-path") === path);
  }
}

async function loadPage(path) {
  setStatus(`Loading ${path}…`);

  if (path === "__runner__") {
    await renderRunner();
    setActiveLink(path);
    setStatus("Runner");
    return;
  }

  const res = await fetch("/docs/" + path, { cache: "no-store" });
  if (!res.ok) throw new Error(`Failed to load ${path}: ${res.status}`);
  const md = await res.text();
  document.getElementById("doc").innerHTML = renderMarkdown(md);
  setActiveLink(path);
  setStatus(path);
}

function html(s) {
  return escapeHtml(String(s ?? ""));
}

function countMatches(s, re) {
  if (!s) return 0;
  const m = s.match(re);
  return m ? m.length : 0;
}

function detectFeatures(src) {
  const features = [];
  const push = (id, label, doc) => features.push({ id, label, doc });

  const has = (re) => re.test(src);

  if (has(/@emp\s+mm\s+off\s*;/)) push("mm_file", "@emp mm off; (file directive)", "07_mm_off.md");
  if (has(/@emp\s+mm\s+off\s*\{/)) push("mm_block", "@emp mm off { ... }", "07_mm_off.md");
  if (has(/@emp\s+off\s*\{/)) push("emp_off", "@emp off { ... }", "06_emp_off.md");
  if (has(/^\s*use\b/m)) push("use", "use imports", "13_modules_packages.md");
  if (has(/^\s*#\s*[A-Za-z_][A-Za-z0-9_]*\b/m)) push("tag", "#tag statements/items", "03_syntax.md");
  if (has(/\bextern\b/)) push("extern", "extern functions", "09_functions.md");
  if (has(/\bunsafe\b/)) push("unsafe", "unsafe", "06_emp_off.md");
  if (has(/\bdefer\b/)) push("defer", "defer", "08_control_flow.md");
  if (has(/\bmatch\b/)) push("match", "match", "11_enums_match.md");
  if (has(/=>/)) push("match_arms", "match arms (=>)", "08_control_flow.md");
  if (has(/\benum\b/)) push("enum", "enum", "11_enums_match.md");
  if (has(/\bstruct\b/)) push("struct", "struct", "10_structs_oop.md");
  if (has(/\bclass\b/)) push("class", "class", "10_structs_oop.md");
  if (has(/\btrait\b/)) push("trait", "trait", "12_traits_ufcs.md");
  if (has(/\bimpl\b/)) push("impl", "impl", "12_traits_ufcs.md");
  if (has(/\bdyn\b/)) push("dyn", "dyn", "04_types.md");
  if (has(/\bnew\b/)) push("new", "new Class(...)", "10_structs_oop.md");
  if (has(/\$"/ ) || has(/\$`/)) push("fstring", "f-strings", "14_strings.md");
  if (has(/::/)) push("ns", "namespace access (::)", "23_grammar_implemented.md");
  if (has(/\bas\b/)) push("as_cast", "casts (as Type)", "23_grammar_implemented.md");
  if (has(/\([iu][0-9]+\)\s*[^\s]/)) push("c_cast", "C-style casts ((i32)expr)", "23_grammar_implemented.md");
  if (has(/\.\./) || has(/\.\.=|\.\.\./)) push("ranges", "range operators (.., ..=, ...)", "03_syntax.md");
  if (has(/\?\s*[^\n]*\s*:/)) push("ternary", "ternary operator (?:)", "03_syntax.md");
  if (has(/\[\s*\]/) || has(/\[[^\]]+\]/)) push("brackets", "[] list literals / indexing", "15_arrays_lists.md");
  if (has(/:\s*[A-Za-z_][A-Za-z0-9_]*\s*\[\s*\]/)) push("list_type", "list types (T[])", "04_types.md");
  if (has(/:\s*[A-Za-z_][A-Za-z0-9_]*\s*\[\s*\d/)) push("array_type", "array types (T[n])", "04_types.md");
  if (has(/\blet\s*\(/)) push("tuple_destructure", "tuple destructuring let (a, b) = ...", "23_grammar_implemented.md");
  if (has(/\bfor\b/)) push("for", "for loops", "08_control_flow.md");
  if (has(/\bfor\s+[A-Za-z_][A-Za-z0-9_]*\s*,\s*[A-Za-z_][A-Za-z0-9_]*\s+in\b/)) push("for_two", "for idx, val in expr", "08_control_flow.md");
  if (has(/\bwhile\b/)) push("while", "while loops", "08_control_flow.md");
  if (has(/\bif\b/)) push("if", "if/else", "08_control_flow.md");
  if (has(/\blet\b/)) push("let", "let bindings", "03_syntax.md");
  if (has(/\b&mut\b/)) push("borrow_mut", "&mut borrow", "04_types.md");
  if (has(/\b&\b/)) push("borrow", "& borrow", "04_types.md");
  if (has(/\bstring\b/) || has(/"/)) push("strings", "string literals", "14_strings.md");
  if (has(/\/\*/) && has(/\*\//)) push("block_comments", "block comments (nestable)", "03_syntax.md");

  // Normalize by id (first occurrence keeps doc link).
  const seen = new Set();
  return features.filter(f => (seen.has(f.id) ? false : (seen.add(f.id), true)));
}

function predict(src, filePath) {
  const isFail = /_fail\.em$/i.test(filePath || "");
  const lines = src.replaceAll("\r\n", "\n").split("\n").length;

  const fnCount = countMatches(src, /\bfn\s+[A-Za-z_][A-Za-z0-9_]*\s*\(/g);
  const useCount = countMatches(src, /^\s*use\b.*?;/gm);
  const matchCount = countMatches(src, /\bmatch\b/g);
  const deferCount = countMatches(src, /\bdefer\b/g);

  const features = detectFeatures(src);

  const keywordList = [
    "fn","auto","let","mut","if","else","while","for","in","return","break","continue",
    "struct","enum","match","defer","true","false","null","export","use","from","as",
    "extern","unsafe","class","trait","virtual","new","impl","const","dyn","mm","emp","off"
  ];
  const foundKeywords = keywordList.filter(k => new RegExp(`\\b${k}\\b`).test(src));

  const passes = [];
  passes.push("Lexer: turns source into tokens (comments/strings/f-strings/ranges/::/=> etc). See #22_lexer_tokens.md");
  passes.push("Parser: builds an AST (items, stmts, expressions, types). See #23_grammar_implemented.md");
  passes.push("Typecheck: resolves names, infers/coerces literals, checks calls/method sugar, validates match arms.");
  passes.push("Borrow/ownership: enforces move/borrow rules unless inside @emp off/@emp mm off regions.");
  passes.push("Drop insertion: inserts deterministic drops (disabled in @emp off/@emp mm off regions).");
  passes.push("Codegen (LLVM): lowers typed AST to LLVM IR and links.");

  const hints = [];
  if (isFail) hints.push("This file name ends with _fail.em, so tests expect the compiler to reject it.");
  if (features.some(f => f.id === "mm_file" || f.id === "mm_block")) {
    hints.push("Manual memory mode is active for at least part of the file; some allocation/free primitives become available and drop insertion is disabled in the region.");
  }
  if (features.some(f => f.id === "emp_off")) {
    hints.push("@emp off disables ownership/borrow checking in that block, but still has 'no escape' boundary checks.");
  }
  if (features.some(f => f.id === "fstring")) {
    hints.push("f-strings parse {expr} interpolations and {{/}} escaping; typecheck only allows certain interpolation types (string/*u8/int/bool/char). ");
  }
  if (features.some(f => f.id === "use")) {
    hints.push("Imports are parsed as a top-level item; module resolution is handled later by the resolver.");
  }

  return {
    filePath,
    isFail,
    stats: { lines, fnCount, useCount, matchCount, deferCount },
    features,
    foundKeywords,
    passes,
    hints,
  };
}

function renderPrediction(pred) {
  const featuresHtml = pred.features.length
    ? pred.features.map(f => `<span class="pill" title="${html(f.id)}"><a href="#${html(f.doc)}">${html(f.label)}</a></span>`).join(" ")
    : `<span class="pill">(no specific features detected)</span>`;

  const kwHtml = pred.foundKeywords && pred.foundKeywords.length
    ? pred.foundKeywords.map(k => `<span class="pill">${html(k)}</span>`).join(" ")
    : `<span class="pill">(none)</span>`;

  const hintsHtml = pred.hints.length
    ? `<ul>${pred.hints.map(h => `<li>${html(h)}</li>`).join("")}</ul>`
    : `<p>No extra hints.</p>`;

  const passesHtml = `<ol>${pred.passes.map(p => `<li>${html(p)}</li>`).join("")}</ol>`;

  return `
    <div class="runner-output">
      <div class="runner-kv">
        <div>File</div><div>${html(pred.filePath || "(pasted)")}${pred.isFail ? " <span class=\"pill\">expected fail</span>" : ""}</div>
        <div>Raw</div><div>${pred.filePath ? `<a href="/${html(pred.filePath)}" target="_blank" rel="noreferrer">open file</a>` : "(n/a)"}</div>
        <div>Lines</div><div>${html(pred.stats.lines)}</div>
        <div>fn</div><div>${html(pred.stats.fnCount)}</div>
        <div>use</div><div>${html(pred.stats.useCount)}</div>
        <div>match</div><div>${html(pred.stats.matchCount)}</div>
        <div>defer</div><div>${html(pred.stats.deferCount)}</div>
      </div>

      <h3>Keywords seen</h3>
      <div>${kwHtml}</div>

      <h3>Syntax features found</h3>
      <div>${featuresHtml}</div>

      <h3>What the compiler is doing (predictor)</h3>
      ${passesHtml}

      <h3>Notes</h3>
      ${hintsHtml}
    </div>
  `;
}

async function renderRunner() {
  const root = document.getElementById("doc");
  root.innerHTML = `
    <div class="runner">
      <h1>Runner (JS predictor)</h1>
      <p>Loads a real <code>.em</code> file from this repo (or a fixed sample) and explains which syntax is present and which compiler passes it exercises.</p>

      <div class="runner-toolbar">
        <label>Group:
          <select id="runnerGroup">
            <option value="all">all</option>
            <option value="tests">tests</option>
            <option value="examples">examples</option>
            <option value="stdlib">stdlib</option>
            <option value="emp_mods">emp_mods</option>
            <option value="misc">misc</option>
          </select>
        </label>
        <label>File:
          <select id="runnerFile"></select>
        </label>
        <button id="runnerLoad">Load file</button>
        <button id="runnerAnalyze">Analyze</button>
      </div>

      <div class="runner-grid">
        <div class="runner-panel">
          <h3>Input (EMP)</h3>
          <textarea id="runnerSrc" class="runner-textarea" spellcheck="false"></textarea>
        </div>
        <div class="runner-panel">
          <h3>Explanation</h3>
          <div id="runnerOut" class="runner-output"></div>
        </div>
      </div>
    </div>
  `;

  const groupSel = document.getElementById("runnerGroup");
  const fileSel = document.getElementById("runnerFile");
  const srcEl = document.getElementById("runnerSrc");
  const outEl = document.getElementById("runnerOut");

  // Fixed starter input (works even if file fetching fails).
  srcEl.value = `fn main() {\n  let xs: auto[] = [];\n  xs.push(1);\n  if xs.len() > 0 {\n    return;\n  }\n}`;

  let index;
  try {
    const res = await fetch("/docs/em_index.json", { cache: "no-store" });
    if (!res.ok) throw new Error(String(res.status));
    index = await res.json();
  } catch (e) {
    outEl.innerHTML = `<p>Failed to load <code>/docs/em_index.json</code>. Start a local server at repo root and open <code>/docs/viewer/</code>.</p>`;
    return;
  }

  function refreshFiles() {
    const grp = groupSel.value;
    const files = (index.files || []).filter(f => grp === "all" ? true : f.group === grp);

    fileSel.innerHTML = "";
    for (const f of files) {
      const opt = document.createElement("option");
      opt.value = f.path;
      opt.textContent = `${f.path}`;
      fileSel.appendChild(opt);
    }

    const want = (index.defaultPath && files.some(f => f.path === index.defaultPath)) ? index.defaultPath : (files[0] ? files[0].path : "");
    if (want) fileSel.value = want;
  }

  groupSel.addEventListener("change", refreshFiles);
  refreshFiles();

  document.getElementById("runnerLoad").addEventListener("click", async () => {
    const path = fileSel.value;
    if (!path) return;
    setStatus(`Loading ${path}…`);
    try {
      const res = await fetch("/" + path, { cache: "no-store" });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      srcEl.value = await res.text();
      setStatus(path);
    } catch (e) {
      setStatus(`Failed to load ${path}`);
      outEl.innerHTML = `<p>Failed to fetch <code>/${html(path)}</code>. Make sure your static server root is the repo root.</p>`;
    }
  });

  document.getElementById("runnerAnalyze").addEventListener("click", () => {
    const path = fileSel.value;
    const src = srcEl.value || "";
    const pred = predict(src, path);
    outEl.innerHTML = renderPrediction(pred);
  });

  // Auto-run once.
  outEl.innerHTML = renderPrediction(predict(srcEl.value, fileSel.value));
}

function buildNav(pages) {
  const nav = document.getElementById("nav");
  nav.innerHTML = "";

  for (const p of pages) {
    const a = document.createElement("a");
    a.href = "#" + encodeURIComponent(p.path);
    a.textContent = p.title;
    a.setAttribute("data-path", p.path);
    a.addEventListener("click", (e) => {
      e.preventDefault();
      location.hash = encodeURIComponent(p.path);
    });
    nav.appendChild(a);
  }
}

function wireSearch(pages) {
  const input = document.getElementById("search");
  input.addEventListener("input", () => {
    const q = input.value.trim().toLowerCase();
    const filtered = q ? pages.filter(p => p.title.toLowerCase().includes(q)) : pages;
    buildNav(filtered);
  });
}

async function main() {
  try {
    const manifest = await loadManifest();
    buildNav(manifest.pages);
    wireSearch(manifest.pages);

    const initial = location.hash ? decodeURIComponent(location.hash.slice(1)) : (manifest.home || "README.md");
    const known = new Set(manifest.pages.map(p => p.path));
    await loadPage(known.has(initial) ? initial : (manifest.home || manifest.pages[0].path));

    window.addEventListener("hashchange", async () => {
      const path = location.hash ? decodeURIComponent(location.hash.slice(1)) : (manifest.home || "README.md");
      if (!known.has(path)) return;
      await loadPage(path);
    });
  } catch (err) {
    setStatus(String(err));
    document.getElementById("doc").innerHTML = "";
  }
}

main();
