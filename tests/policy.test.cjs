const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const { execFileSync } = require('node:child_process');

const root = path.resolve(__dirname, '..');
const read = (file) => fs.readFileSync(path.join(root, file), 'utf8');
const skillPaths = [
  'plugins/codegraph/skills/using-codegraph/SKILL.md',
  'plugins/development-loop/skills/development-loop/SKILL.md',
  'plugins/cross-repo-completeness/skills/cross-repo-completeness/SKILL.md',
];
const block = execFileSync('bash', [path.join(root,
  'plugins/development-loop/skills/development-loop/scripts/install.sh'), '--print-only'],
{ encoding: 'utf8' });

for (const file of [...skillPaths, 'README.md']) {
  test(`${file}: closes cold indexes while honoring user restrictions`, () => {
    const text = read(file);
    assert.match(text, /codegraph init \./u);
    assert.match(text, /codegraph sync \./u);
    assert.match(text, /explicit user\s+(?:no-index|indexing) restriction/iu);
    assert.doesNotMatch(text, /skip it when there is no|indexing is the repo owner's choice/iu);
  });
  test(`${file}: reports unsupported files honestly`, () => {
    const text = read(file);
    assert.match(text, /unsupported/iu);
    assert.match(text, /empty/iu);
    assert.match(text, /direct(?:ly)? (?:reads?|inspect)/iu);
  });
}

for (const [file, load] of [
  ...[...skillPaths, 'README.md', 'AGENTS.md'].map((f) => [f, () => read(f)]),
  ['install.sh managed block', () => block],
]) {
  test(`${file}: creating and syncing the index is mandatory, not a default`, () => {
    const text = load();
    assert.match(text, /\bsync(?:ing)?\b[^.]{0,40}\bmandatory\b|\bmandatory\b[^.]{0,40}\bsync\b/iu);
    assert.match(text, /without\s+asking/iu);
    assert.match(text, /after\s+(?:pulls|pulling)[^.]{0,40}(?:branch\s+switches|switching\s+branches)/iu);
    assert.match(text, /prohibition\s+on\s+all\s+writes/iu);
    assert.match(text, /user's\s+decision[^.]{0,20}(?:text\s+)?(?:is|are)\s+tool\s+guidance/iu);
    assert.doesNotMatch(text,
      /overrides? (?:this|the) default|(?:gaps|indexing)[^.]{0,60}by default|Default policy|for the current task/iu);
  });
  test(`${file}: source-read-only work still indexes; no-behavior edits need no index`, () => {
    const text = load();
    assert.match(text, /source-read-only\s+task\s+still\s+creates\s+and\s+syncs\s+the\s+index/iu);
    assert.doesNotMatch(text, /source-read-only[^.]{0,80}counts\s+as\s+a\s+no-index\s+restriction/iu);
    assert.match(text, /no\s+behavior\s+change\s+does\s+not\s+need\s+an\s+index/iu);
  });
}

test('cold-repo skill is discoverable before an index exists', () => {
  const description = read(skillPaths[0]).split('\n').find((line) => line.startsWith('description:'));
  assert.match(description, /missing|absent|unindexed/u);
});

test('managed block names skills and the complete execution chain', () => {
  for (const name of [
    'development-loop', 'using-codegraph', 'cross-repo-completeness',
    'superpowers:brainstorming', 'superpowers:writing-plans',
    'superpowers:test-driven-development', 'superpowers:subagent-driven-development',
    'superpowers:executing-plans', 'superpowers:requesting-code-review',
    'superpowers:verification-before-completion', 'superpowers:finishing-a-development-branch',
  ]) assert.ok(block.includes('`' + name + '`'), `missing exact skill ${name}`);
  assert.match(block, /codegraph init \./u);
  assert.match(block, /codegraph sync \./u);
  assert.match(block, /explicit user (?:no-index|indexing) restriction/iu);
  assert.match(block, /unsupported/iu);
});

test('development loop explicitly routes bug diagnosis, reviews and inline execution', () => {
  const text = read(skillPaths[1]);
  for (const name of [
    'using-codegraph', 'cross-repo-completeness', 'superpowers:systematic-debugging',
    'superpowers:executing-plans', 'superpowers:requesting-code-review',
    'superpowers:receiving-code-review', 'superpowers:verification-before-completion',
  ]) assert.ok(text.includes('`' + name + '`'), `missing ${name}`);
  assert.match(text, /(?:push|remote writes)[\s\S]{0,70}authoriz/iu);
});

test('changed plugins invalidate known installed caches', () => {
  for (const [name, version] of [
    ['codegraph', '1.2.1'], ['development-loop', '1.2.1'], ['cross-repo-completeness', '1.1.1'],
  ]) assert.equal(JSON.parse(read(`plugins/${name}/.claude-plugin/plugin.json`)).version, version);
});

// --- printable-parts plugin ------------------------------------------------

const ppPlugin = () =>
  JSON.parse(read('plugins/printable-parts/.claude-plugin/plugin.json'));
const marketplace = () => JSON.parse(read('.claude-plugin/marketplace.json'));
const ppSkill = () => read('plugins/printable-parts/skills/printable-parts/SKILL.md');

function walkFiles(dir) {
  const out = [];
  for (const ent of fs.readdirSync(path.join(root, dir), { withFileTypes: true })) {
    const rel = path.join(dir, ent.name);
    if (ent.isDirectory()) out.push(...walkFiles(rel));
    else out.push(rel);
  }
  return out;
}

test('printable-parts: marketplace entry and plugin metadata are consistent', () => {
  const entry = marketplace().plugins.find((p) => p.name === 'printable-parts');
  assert.ok(entry, 'printable-parts missing from marketplace.json');
  assert.equal(entry.source, './plugins/printable-parts');
  const plugin = ppPlugin();
  assert.equal(plugin.name, 'printable-parts');
  assert.equal(plugin.version, '1.0.0');
  // Description consistent across the two manifests (AGENTS.md requirement).
  assert.equal(plugin.description, entry.description);
  assert.match(plugin.description, /text-to-cad/u);
  assert.match(plugin.description, /Start with the printable-parts skill\./u);
});

test('printable-parts: SKILL.md description says what it does and when to use it', () => {
  const text = ppSkill();
  const fm = text.split('---')[1] || '';
  const desc = (fm.match(/description:\s*([\s\S]*?)\nlicense:/u) || [])[1] || '';
  // Anthropic's guidance (owner's tie-breaker): what it does AND when to use.
  assert.match(desc, /\bUse when\b/u);
  assert.match(desc, /text-to-cad/u);
  // Trigger nouns the soft layer competes for.
  for (const noun of ['mount', 'bracket', 'clip', 'perch', 'enclosure']) {
    assert.ok(desc.includes(noun), `description missing trigger noun ${noun}`);
  }
  // Third person: no first/second person openers.
  assert.doesNotMatch(desc, /\b(I can|I will|you can use this)\b/iu);
});

test('printable-parts: SKILL.md composes text-to-cad by name and stays an overview', () => {
  const text = ppSkill();
  assert.match(text, /REQUIRED SUB-SKILL:\*\*\s*`?cad`?/u);
  assert.match(text, /`?print3d`?/u);
  assert.match(text, /never\s+(?:vendors?|edits?)\s+it|never vendors or edits it/iu);
  // Under 500 lines (Anthropic's budget).
  assert.ok(text.split('\n').length < 500, 'SKILL.md body should stay under 500 lines');
});

test('printable-parts: the enforcement reference documents the per-runtime limit', () => {
  const text = read(
    'plugins/printable-parts/skills/printable-parts/references/enforcement.md'
  );
  assert.match(text, /PreToolUse/u);
  assert.match(text, /fail(?:s)?\s+open/iu);
  // The hook is Claude Code only; other runtimes get the soft + repo layers.
  assert.match(text, /Claude Code only|Claude Code\b[^.]*hook/iu);
  assert.match(text, /Codex/u);
});

test('printable-parts: hook manifest gates the Bash tool before it runs', () => {
  const hooks = JSON.parse(
    read('plugins/printable-parts/hooks/hooks.json')
  );
  const pre = hooks.hooks.PreToolUse;
  assert.ok(Array.isArray(pre) && pre.length >= 1);
  assert.equal(pre[0].matcher, 'Bash');
  assert.match(pre[0].hooks[0].command, /guard-printable-mesh\.js/u);
});

test('printable-parts: README documents the plugin, the install, and the hook limit', () => {
  const text = read('README.md');
  assert.match(text, /### printable-parts/u);
  assert.match(text, /\/plugin install printable-parts@doyled-it-skills/u);
  assert.match(text, /hook is Claude Code only/iu);
});

test('printable-parts: no em dashes in the plugin or its tests', () => {
  const files = [
    ...walkFiles('plugins/printable-parts'),
    ...walkFiles('tests/printable-parts'),
  ];
  for (const file of files) {
    if (/\.(md|json|js|py|sh|cjs)$/u.test(file)) {
      assert.ok(!read(file).includes('—'), `em dash in ${file}`);
    }
  }
});

test('canonical instructions and generated state conventions exist', () => {
  assert.equal(read('CLAUDE.md').trim(), '@AGENTS.md');
  for (const name of ['development-loop', 'using-codegraph', 'cross-repo-completeness']) {
    assert.ok(read('AGENTS.md').includes('`' + name + '`'));
  }
  for (const dir of ['.codegraph/', '.superpowers/']) assert.ok(read('.gitignore').includes(dir));
});
