#!/bin/bash

source "$(dirname "$0")/base-test.sh"

TEST_HOME=$(mktemp -d)
trap 'rm -rf "$TEST_HOME"' EXIT

FAKE_BIN="$TEST_HOME/bin"
CURRENT_THEME="$TEST_HOME/.local/state/omarchy/current/theme"
mkdir -p "$FAKE_BIN" "$CURRENT_THEME"

cat >"$FAKE_BIN/omarchy-cmd-present" <<'EOF'
#!/bin/bash
printf '%s\n' "$1" >>"$EDITOR_PROBE_LOG"
exit 1
EOF

cat >"$FAKE_BIN/omarchy-toggle-enabled" <<'EOF'
#!/bin/bash
exit 1
EOF

cat >"$FAKE_BIN/cursor" <<'EOF'
#!/bin/bash
touch "$CURSOR_SHIM_CALLED"
exit 1
EOF

chmod +x "$FAKE_BIN"/*
printf '{"name":"Hackerman","extension":"akamud.vscode-theme-onedark"}\n' >"$CURRENT_THEME/vscode.json"

EDITOR_PROBE_LOG="$TEST_HOME/editor-probes.log" \
  CURSOR_SHIM_CALLED="$TEST_HOME/cursor-shim-called" \
  PATH="$FAKE_BIN:$ROOT/bin:$PATH" \
  HOME="$TEST_HOME" \
  "$ROOT/bin/omarchy-theme-set-vscode"

grep -Fxq '/usr/bin/cursor' "$TEST_HOME/editor-probes.log" || fail "VS Code theme sync probes the packaged Cursor executable"
[[ ! -e $TEST_HOME/cursor-shim-called ]] || fail "VS Code theme sync ignores a PATH-provided Cursor Agent shim"
[[ ! -e $TEST_HOME/.config/Cursor/User/settings.json ]] || fail "VS Code theme sync skips Cursor when the packaged executable is unavailable"
pass "VS Code theme sync selects the packaged Cursor executable"

# A theme extension that fails to install leaves settings.json as it was, so VS Code keeps a theme
# it has; one that installs is selected.
mkdir -p "$TEST_HOME/.config/Code/User"
printf '{\n  "workbench.colorTheme": "Ocean Green"\n}\n' >"$TEST_HOME/.config/Code/User/settings.json"
printf '{"name":"Tokyo Night","extension":"enkia.tokyo-night"}\n' >"$CURRENT_THEME/vscode.json"
cat >"$FAKE_BIN/omarchy-cmd-present" <<'EOF2'
#!/bin/bash
[[ $1 == code ]]
EOF2
cat >"$FAKE_BIN/code" <<'EOF2'
#!/bin/bash
case $1 in
  --list-extensions) [[ -f $CODE_INSTALLED ]] && echo enkia.tokyo-night; exit 0 ;;
  --install-extension) [[ -n $CODE_INSTALL_WORKS ]] && touch "$CODE_INSTALLED"; exit 0 ;;
esac
EOF2
chmod +x "$FAKE_BIN/omarchy-cmd-present" "$FAKE_BIN/code"

err=$(CODE_INSTALLED="$TEST_HOME/installed" PATH="$FAKE_BIN:$ROOT/bin:$PATH" HOME="$TEST_HOME" \
  "$ROOT/bin/omarchy-theme-set-vscode" 2>&1 >/dev/null)
grep -q '"workbench.colorTheme": "Ocean Green"' "$TEST_HOME/.config/Code/User/settings.json" ||
  fail "a failed theme extension install leaves VS Code's theme as it was" "$(cat "$TEST_HOME/.config/Code/User/settings.json")"
grep -q 'could not install enkia.tokyo-night' <<<"$err" || fail "a failed theme extension install is reported" "$err"
pass "a failed theme extension install leaves VS Code's theme as it was"

CODE_INSTALLED="$TEST_HOME/installed" CODE_INSTALL_WORKS=1 PATH="$FAKE_BIN:$ROOT/bin:$PATH" HOME="$TEST_HOME" \
  "$ROOT/bin/omarchy-theme-set-vscode" 2>/dev/null
grep -q '"workbench.colorTheme": "Tokyo Night"' "$TEST_HOME/.config/Code/User/settings.json" ||
  fail "an installed theme extension is selected" "$(cat "$TEST_HOME/.config/Code/User/settings.json")"
pass "an installed theme extension is selected"

# --list-extensions prints ids in lowercase; a theme that names its extension with capitals
# ("shadesOfBuntu.flexoki-light") is still found installed, and selected.
printf '{\n  "workbench.colorTheme": "Tokyo Night"\n}\n' >"$TEST_HOME/.config/Code/User/settings.json"
printf '{"name":"flexoki-light","extension":"shadesOfBuntu.flexoki-light"}\n' >"$CURRENT_THEME/vscode.json"
cat >"$FAKE_BIN/code" <<'EOF2'
#!/bin/bash
case $1 in
  --list-extensions) echo shadesofbuntu.flexoki-light; exit 0 ;;
  --install-extension) touch "$CODE_INSTALL_CALLED"; exit 0 ;;
esac
EOF2
chmod +x "$FAKE_BIN/code"

err=$(CODE_INSTALL_CALLED="$TEST_HOME/install-called" PATH="$FAKE_BIN:$ROOT/bin:$PATH" HOME="$TEST_HOME" \
  "$ROOT/bin/omarchy-theme-set-vscode" 2>&1 >/dev/null)
grep -q '"workbench.colorTheme": "flexoki-light"' "$TEST_HOME/.config/Code/User/settings.json" ||
  fail "a theme naming its extension with capitals is selected" "$(cat "$TEST_HOME/.config/Code/User/settings.json") $err"
[[ ! -e $TEST_HOME/install-called ]] || fail "an installed extension named with capitals is not installed again"
pass "a theme naming its extension with capitals is found installed and selected"
