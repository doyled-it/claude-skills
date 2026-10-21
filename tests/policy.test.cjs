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
    ['codegraph', '1.2.0'], ['development-loop', '1.2.0'], ['cross-repo-completeness', '1.1.0'],
  ]) assert.equal(JSON.parse(read(`plugins/${name}/.claude-plugin/plugin.json`)).version, version);
});

test('canonical instructions and generated state conventions exist', () => {
  assert.equal(read('CLAUDE.md').trim(), '@AGENTS.md');
  for (const name of ['development-loop', 'using-codegraph', 'cross-repo-completeness']) {
    assert.ok(read('AGENTS.md').includes('`' + name + '`'));
  }
  for (const dir of ['.codegraph/', '.superpowers/']) assert.ok(read('.gitignore').includes(dir));
});
