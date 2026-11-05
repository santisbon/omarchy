#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const text = fs.readFileSync(path.join(root, 'default/omarchy/omarchy-menu.jsonc'), 'utf8')
const rows = Object.fromEntries(text.split('\n').filter(line => /^  "/.test(line)).map(line => {
  const object = JSON.parse('{' + line.trim().replace(/,$/, '') + '}')
  return Object.entries(object)[0]
}))
assert(rows['remove.dictation'] && !rows['remove.ai.dictation'], 'Dictation retains its baseline location')
// The port deleted Install > AI's T3 Code, Hermes Desktop, OpenClaw and Perplexity entries with
// their installers and removers, and Remove > AI with them (port commit ef4c9211; PORT.md, "Not
// included"), so no Remove > AI entry is left.
assert(!Object.keys(rows).some(k => k === 'remove.ai' || k.startsWith('remove.ai.')), 'no Remove > AI entry outlives its deleted removers')
assertDeepEqual(Object.keys(rows).filter(k => k.startsWith('setup.default.agent.')).map(k => k.split('.').pop()).sort(), ['agy', 'amp', 'claude', 'codex', 'commandcode', 'copilot', 'crush', 'cursor-agent', 'devin', 'dsh', 'freebuff', 'grok', 'hermes', 'kilo', 'kimi', 'kiro-cli', 'mcode', 'muse', 'omp', 'opencode', 'ori', 'pi', 'qwen'], 'baseline agent choices survive, without the OpenClaw agent the port dropped')
for (const id of ['setup.default.agent.cursor-agent', 'setup.default.editor.cursor']) {
  assertEqual(rows[id].icon, '\ue90d', `${id} uses the upstream Cursor glyph`)
  assertEqual(rows[id].iconFont, 'omarchy', `${id} uses the packaged icon font`)
}
assert(!rows['setup.default.editor.cursor'].when, 'Cursor editor stays listed under Setup > Defaults, as v4.5.0 has it')
assertEqual(rows['setup.default.agent.muse'].icon, '\ue91f', 'Muse uses its mark in the Omarchy font')
assertEqual(rows['setup.default.agent.muse'].iconFont, 'omarchy', 'Muse draws its mark in the Omarchy font')
assert(!fs.existsSync(path.join(root, 'bin/omarchy-theme-set-openclaw')), 'deferred OpenClaw theming is absent')
JS

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT
mkdir -p "$test_tmp/bin"
export TEST_CALLS="$test_tmp/calls"
cat >"$test_tmp/bin/mise" <<'SH'
#!/bin/bash
printf 'mise:%s\n' "$*" >>"$TEST_CALLS"
SH
chmod +x "$test_tmp/bin"/*
# mise.sh asks omarchy-cmd-missing whether mise is installed, so the real helper has to be on
# PATH behind the stub.
PATH="$test_tmp/bin:$ROOT/bin:$PATH" bash -eE "$ROOT/install/user/mise.sh"
grep -qx 'mise:reshim --system' "$TEST_CALLS" && grep -qx 'mise:reshim' "$TEST_CALLS" ||
  fail "new users get the lazy shims for the tools /etc/mise/conf.d declares" "$(cat "$TEST_CALLS")"
pass "mise setup builds the lazy shims without the network"

# Exercise the documented font workflow, not just fontconfig's charset reader.
# Work on a disposable copy: adding a fixture must never edit the source font.
python3 - "$ROOT" "$test_tmp" <<'PY'
import pathlib
import runpy
import shutil
import struct
import subprocess
import sys

root, temporary = map(pathlib.Path, sys.argv[1:])
tool = root / 'bin/omarchy-dev-font'
font = temporary / 'omarchy.ttf'
shutil.copyfile(root / 'default/fonts/omarchy/omarchy.ttf', font)
api = runpy.run_path(str(tool))

def snapshot():
    data, tables, count = api['load_font'](str(font))
    offsets = api['read_loca'](data, tables, count)
    names = api['read_names'](data, tables['post'][0], count)
    cmap = api['read_cmap'](data, tables['cmap'][0])
    start = tables['glyf'][0]
    glyphs = [data[start + offsets[i]:start + offsets[i + 1]].rstrip(b'\0') for i in range(count)]
    metrics = data[tables['hmtx'][0]:sum(tables['hmtx'])]
    assert struct.unpack_from('>I', data, tables['post'][0])[0] == 0x20000
    return names, cmap, glyphs, metrics

before = snapshot()
assert before[0][before[1][0xE90D]] == 'cursor'
listing = subprocess.check_output([sys.executable, str(tool), 'list', '--font', str(font)], text=True)
for cp, name, _ in api['glyph_list'](str(font)):
    assert f'U+{cp:04X}' in listing and name in listing
assert 'U+E90D' in listing and 'cursor' in listing
print('ok - the shipped font lists its named Cursor mark through the real font tool')

svg = temporary / 'fixture.svg'
svg.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M2 2 L22 2 L22 22 L2 22 Z"/></svg>')
subprocess.run([sys.executable, str(tool), 'add', 'release-fixture', str(svg), '--font', str(font)], check=True, stdout=subprocess.DEVNULL)
after = snapshot()
assert after[0] == before[0] + ['release-fixture']
assert after[1] == before[1] | {0xE920: len(before[0])}
assert after[2][:-1] == before[2]
assert after[3].startswith(before[3])
print('ok - adding a local SVG preserves every existing name, codepoint, outline and metric')
listing = subprocess.check_output([sys.executable, str(tool), 'list', '--font', str(font)], text=True)
assert 'U+E920' in listing and 'release-fixture' in listing and 'cursor' in listing
print('ok - the real font tool lists the newly added disposable glyph')
unchanged = font.read_bytes()
result = subprocess.run([sys.executable, str(tool), 'add', 'collision', str(svg), '--codepoint', 'E90D', '--font', str(font)], capture_output=True, text=True)
assert result.returncode != 0 and 'already used' in result.stderr
assert font.read_bytes() == unchanged
print('ok - adding over Cursor is rejected without changing the font')
PY
