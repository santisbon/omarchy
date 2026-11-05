#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const search = requireFromRoot('shell/services/AppSearch.js')

const entries = [
  {
    name: 'Google Contacts',
    genericName: 'Address Book',
    comment: 'Manage contacts',
    keywords: ['contacts', 'address book', 'people'],
    id: 'google-contacts.desktop'
  },
  {
    name: 'Calculator',
    genericName: 'Calculator',
    comment: 'Perform arithmetic, scientific or financial calculations',
    keywords: ['calculation', 'arithmetic', 'scientific', 'financial'],
    id: 'org.gnome.Calculator.desktop'
  },
  {
    name: 'OBS Studio',
    genericName: 'Streaming/Recording Software',
    comment: 'Free and Open Source Streaming/Recording Software',
    keywords: ['streaming', 'recording', 'capture'],
    id: 'com.obsproject.Studio.desktop'
  },
  {
    name: 'Aether',
    genericName: '',
    comment: 'Minimal internet radio player',
    keywords: ['audio', 'music', 'radio'],
    id: 'io.github.taqi.aether.desktop'
  },
  {
    name: 'Xournal++',
    genericName: 'Notetaking',
    comment: 'Take handwritten notes',
    keywords: ['notes', 'pdf', 'annotation'],
    id: 'com.github.xournalpp.xournalpp.desktop'
  },
  {
    name: 'RustDesk',
    genericName: 'Remote Desktop',
    comment: 'Remote desktop control',
    keywords: ['remote', 'desktop', 'control'],
    id: 'com.rustdesk.RustDesk.desktop'
  }
]

// Keep the packaged launcher when upstream rebuilds register their own entry.
const configuredHides = new Set(fs.readFileSync(path.join(root, 'default/omarchy/launcher.hides'), 'utf8').trim().split(/\n/))
const hermesEntries = [{ name: 'Hermes', id: 'hermes' }, { name: 'Hermes', id: 'hermes-desktop' }]
for (const query of ['', 'hermes']) {
  const visible = search.sortedEntries(hermesEntries, query, entry => configuredHides.has(entry.id))
  assertDeepEqual(visible.map(row => row.entry.id), ['hermes-desktop'], 'only the packaged Hermes launcher is visible')
}

const contactMatches = search.sortedEntries(entries, 'contact').map(row => search.entryName(row.entry))
assertDeepEqual(contactMatches, ['Google Contacts'], 'contact search only returns direct contact matches')

assert(
  search.fuzzyScore(entries[1], 'contact') < 0,
  'calculator does not match contact as a loose subsequence'
)

const acronymMatches = search.sortedEntries(entries, 'gc').map(row => search.entryName(row.entry))
assertEqual(acronymMatches[0], 'Google Contacts', 'short acronym matching still works')

const directMatches = search.sortedEntries(entries, 'obs').map(row => search.entryName(row.entry))
assertEqual(directMatches[0], 'OBS Studio', 'direct app-name matching still works')

// The port routes launches through bin/omarchy-launch-desktop, which runs the same
// "uwsm-app -- gtk-launch" and adds discrete-GPU offload on hybrid graphics (commit dfe338ce).
const appLibraryQml = fs.readFileSync(path.join(root, 'shell/services/AppLibrary.qml'), 'utf8')
assert(
  /function launch\(desktopId, name\) \{[\s\S]*?omarchy-launch-desktop[\s\S]*?\n  \}/.test(appLibraryQml) &&
    appLibraryQml.includes('Util.execDetached(Util.shellQuote(root.omarchyPath + "/bin/omarchy-launch-desktop")') &&
    fs.readFileSync(path.join(root, 'bin/omarchy-launch-desktop'), 'utf8').includes('cmd=(uwsm-app -- gtk-launch "$id.desktop")'),
  'app library launches desktop entries through gtk-launch in their own scope'
)
assert(
  appLibraryQml.includes('Util.shellQuote(id + ".desktop")'),
  'app library launches by full file name so ids ending in .desktop (org.telegram.desktop) resolve'
)
JS
