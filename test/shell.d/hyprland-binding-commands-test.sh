#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

require_command lua
require_command python3

# What every default keybinding runs. The conflict test checks which keys are bound; this one
# checks the other half: that each binding's command names a script that exists, a menu route
# the menu resolves, and a shell IPC target and method the shell answers. Super+Space stopped
# opening the menu after an update (2026-10-17), and no test looked at what the keys run.

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# The shipped user config (config/hypr, which /etc/skel carries) loads the defaults the way
# Hyprland does, and a stub Voxtype adds its conditional bindings, so the check covers the
# largest set a new user gets.
home="$tmpdir/home"
stub_bin="$tmpdir/bin"
mkdir -p "$home/.config" "$stub_bin"
cp -r "$ROOT/config/hypr" "$home/.config/hypr"
touch "$stub_bin/voxtype"
chmod +x "$stub_bin/voxtype"

# One line per binding: keys, description, command (empty for a dispatcher that is not a command).
bindings=$(HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_STATE_HOME="$home/.local/state" OMARCHY_PATH="$ROOT" PATH="$stub_bin:$PATH" \
  lua - "$home/.config/hypr/hyprland.lua" <<'LUA'
local function proxy()
  return setmetatable({}, {
    __index = function(self, key)
      local value = proxy()
      rawset(self, key, value)
      return value
    end,
    __call = function() return {} end,
  })
end

local dsp = proxy()
rawset(dsp, "exec_cmd", function(command) return { command = command } end)

local bindings = {}
hl = setmetatable({
  dsp = dsp,
  bind = function(keys, dispatcher, opts)
    opts = opts or {}
    local command = type(dispatcher) == "table" and dispatcher.command or ""
    table.insert(bindings, { keys = keys, description = opts.description or "", command = command })
  end,
  get_config = function() return nil end,
  get_active_window = function() return nil end,
}, {
  __index = function() return function() return {} end end,
})

dofile(arg[1])

for _, b in ipairs(bindings) do
  print(b.keys .. "\t" .. b.description .. "\t" .. b.command)
end
LUA
) || fail "the default bindings load through the shipped hyprland.lua"

(( $(wc -l <<<"$bindings") > 150 )) || fail "the command check sees the full default binding set" "$bindings"
grep -Fq $'SUPER + SPACE\tOmarchy menu\tomarchy-menu toggle' <<<"$bindings" ||
  fail "the command check sees what Super+Space runs" "$(grep '^SUPER + SPACE' <<<"$bindings")"
pass "the command check covers the full default binding set"

# The checker reads the bindings on stdin and prints one line per problem.
cat >"$tmpdir/check.py" <<'PY'
import json, os, re, shlex, sys

root = sys.argv[1]
problems = []

# Menu routes: an item id, one of its aliases (default/omarchy/omarchy-menu.jsonc, one item per
# line), or root.
routes = {"root"}
for line in open(os.path.join(root, "default/omarchy/omarchy-menu.jsonc"), encoding="utf-8"):
    m = re.match(r'\s*"([^"]+)"\s*:\s*\{', line)
    if not m:
        continue
    routes.add(m.group(1))
    a = re.search(r'"aliases"\s*:\s*\[([^\]]*)\]', line)
    if a:
        routes.update(x.lower() for x in re.findall(r'"([^"]+)"', a.group(1)))

# Shell IPC: each IpcHandler's target and the functions declared in the same file; the shell's
# own handler (target "shell") is in shell.qml. Plugin ids from the built-in manifests.
targets = {}
plugin_ids = set()
for dirpath, _, files in os.walk(os.path.join(root, "shell")):
    for name in files:
        path = os.path.join(dirpath, name)
        if name.endswith(".qml"):
            text = open(path, encoding="utf-8").read()
            functions = set(re.findall(r'function\s+(\w+)\s*\(', text))
            for target in re.findall(r'target:\s*"([^"]+)"', text):
                targets.setdefault(target, set()).update(functions)
        elif name == "manifest.json" or name.endswith(".manifest.json"):
            try:
                pid = json.load(open(path, encoding="utf-8")).get("id")
            except ValueError:
                continue
            if pid:
                plugin_ids.add(pid)

def programs(words):
    """The programs a command line runs: its first word, each word after || && ; |, and the
    program a launcher wraps (uwsm-app -- <program>)."""
    found, start = [], True
    for i, w in enumerate(words):
        if w in ("||", "&&", ";", "|"):
            start = True
            continue
        if start:
            if re.match(r'^\w+=', w):
                continue
            found.append((w, words[i + 1:]))
            start = False
        if w == "--" and i > 0 and words[i - 1] == "uwsm-app" and i + 1 < len(words):
            found.append((words[i + 1], words[i + 2:]))
    return found

for line in sys.stdin:
    keys, description, command = (line.rstrip("\n").split("\t") + ["", ""])[:3]
    if not command:
        continue
    where = f"{keys} ({description}): {command}"
    try:
        words = shlex.split(command)
    except ValueError as e:
        problems.append(f"{where}: cannot parse ({e})")
        continue
    # Commands inside single quotes are themselves command lines (omarchy-launch-or-focus).
    inner = []
    for w in words:
        if " " in w and w.startswith(("uwsm-app ", "/")):
            try:
                inner.append(shlex.split(w))
            except ValueError:
                pass
    for words_ in [words] + inner:
        for program, args in programs(words_):
            if program.startswith("omarchy-"):
                path = os.path.join(root, "bin", program)
                if not (os.path.isfile(path) and os.access(path, os.X_OK)):
                    problems.append(f"{where}: {program} is not an executable in bin/")
                    continue
            if program == "omarchy-menu" and len(args) >= 2 and args[0] in ("toggle", "summon"):
                if args[1].lower() not in routes:
                    problems.append(f"{where}: menu route {args[1]} is not in omarchy-menu.jsonc")
            if program == "omarchy-shell":
                a = [x for x in args if x != "-q"]
                if len(a) < 2:
                    problems.append(f"{where}: omarchy-shell needs a target and a method")
                    continue
                target, method = a[0], a[1]
                if target not in targets:
                    problems.append(f"{where}: no IpcHandler answers target {target}")
                elif method not in targets[target]:
                    problems.append(f"{where}: target {target} has no function {method}")
                elif target == "shell" and method in ("toggle", "summon", "hide") and len(a) >= 3 and a[2] not in plugin_ids:
                    problems.append(f"{where}: no built-in plugin has the id {a[2]}")

print("\n".join(problems))
PY

problems=$(python3 "$tmpdir/check.py" "$ROOT" <<<"$bindings") || fail "the command checker runs" "$problems"
[[ -z $problems ]] || fail "every binding's command names a script, menu route and shell target that exist" "$problems"
pass "every binding's command names a script, menu route and shell target that exist"

# Guard the guard: a binding to a missing script, an unknown menu route and an unknown shell
# target must each be caught, or the check above passes by not looking.
probe=$(printf '%s\n' \
  $'SUPER + F1\tProbe\tomarchy-no-such-script' \
  $'SUPER + F2\tProbe\tomarchy-menu toggle no-such-route' \
  $'SUPER + F3\tProbe\tomarchy-shell shell toggle oaxaca.menu' \
  $'SUPER + F4\tProbe\tomarchy-shell no-such-target ping')
probe_problems=$(python3 "$tmpdir/check.py" "$ROOT" <<<"$probe")
for expected in "omarchy-no-such-script is not an executable" "menu route no-such-route" \
  "no built-in plugin has the id oaxaca.menu" "no IpcHandler answers target no-such-target"; do
  grep -Fq "$expected" <<<"$probe_problems" || fail "the command check catches: $expected" "$probe_problems"
done
pass "the command check catches missing scripts, menu routes, plugin ids and shell targets"
