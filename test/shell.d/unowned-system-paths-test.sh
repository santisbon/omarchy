#!/bin/bash

# A file Omarchy writes into /usr belongs to nobody, and the day an Ubuntu
# package starts shipping that same path, dpkg unpacks the package's copy over
# Omarchy's and the two keep fighting over the path at every upgrade. The answer
# is to ship the file in the distro's packaging instead.
#
# This flags a script writing such a path unless the distro's packaging (the
# debian/ directories under packages/ in santisbon/oaxaca) names it, or it is
# recorded below with the reason it cannot be packaged.
#
# It is a net, not a proof: it reads the destination off the command, so a path
# assembled from variables passes through. The two known cases are recorded
# below, and a new one is caught only if it names the path where it writes it.

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

python3 - "$ROOT" <<'PYTHON'
import os, re, sys
from pathlib import Path

root = Path(sys.argv[1])

# Paths Omarchy writes into /usr that no package owns, with the reason.
allowed = {
  # Written through a variable, so the scan below cannot see them at the point
  # they are written. Both drop configuration into another project's tree rather
  # than Omarchy's, which is why neither is a candidate for the distro's packages.
  "/usr/share/chromium/extensions",
  "/usr/lib/firefox/distribution",
  # Seeded by omarchy-install-browser only when the browser is installed, into
  # the browser package's own tree.
  "/usr/lib/chromium/initial_preferences",
}

# The distro's build repository, santisbon/oaxaca, whose packages/*/debian
# directories hold every install rule for the port's packages.
distro_candidates = [
  root.parent / "oaxaca",
  root.parent / "mydistro",
]
override = os.environ.get("OAXACA_PATH")
if override:
  distro_candidates = [Path(override)] + distro_candidates
distro_root = next((p for p in distro_candidates if (p / "packages").is_dir()), None)
if distro_root is None:
  print("not ok - santisbon/oaxaca checkout found for package ownership check", file=sys.stderr)
  sys.exit(1)

packaged = "\n".join(
  p.read_text(errors="ignore") for p in distro_root.glob("packages/*/debian/**/*") if p.is_file()
)

# Commands that put a file somewhere, as opposed to reading one.
# /etc is administrator territory that Omarchy legitimately edits. /usr is
# package territory, where writing anything is the thing worth catching.
writer = re.compile(r"\b(tee|cp|install|ln)\b|>\s*/usr/")
target = re.compile(r"/usr/[A-Za-z0-9._@/+-]+")

problems = []
for base in ("bin", "install", "migrations"):
  for path in sorted((root / base).rglob("*")):
    if not path.is_file():
      continue
    rel = str(path.relative_to(root))
    # Join continuations first, so a command split across lines is judged whole
    # rather than as a source path on one line and a destination on the next.
    joined, buf, start = [], "", 1
    for lineno, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
      if not buf:
        start = lineno
      if line.rstrip().endswith("\\"):
        buf += line.rstrip()[:-1] + " "
        continue
      joined.append((start, buf + line))
      buf = ""
    if buf:
      joined.append((start, buf))

    for lineno, line in joined:
      code = line.split("#", 1)[0]
      if not writer.search(code):
        continue
      # A redirection names its destination directly. Otherwise cp/install/ln
      # put the destination last, and anything earlier is a source being read.
      redirect = re.search(r">\s*\"?(/usr/[^\s\"]+)", code)
      if redirect:
        hit = redirect.group(1).rstrip("/")
      else:
        tokens = re.sub(r"[12]?>\s*\S+", "", code).split()
        if not tokens or not tokens[-1].startswith("/usr/"):
          continue
        hit = tokens[-1].rstrip("/")
      # Omarchy's own tree and its binaries are covered elsewhere.
      if hit.startswith(("/usr/share/omarchy", "/usr/bin")) or hit.count("/") < 3:
        continue
      # Directory or file form of a recorded path both count as recorded, but
      # only on a path boundary: system-sleeping is not system-sleep.
      def covers(a, b):
        return a == b or b.startswith(a + "/")
      if any(covers(a, hit) or covers(hit, a) for a in allowed):
        continue
      # Likewise in the debian/ packaging text, where the path is a destination rather
      # than a prefix of a longer one.
      if re.search(re.escape(hit) + r'(?=["\'\s]|$)', packaged, re.M):
        continue
      problems.append(f"{rel}:{lineno}: {hit}")

if problems:
  print("not ok - Omarchy writes paths under /usr that no package owns", file=sys.stderr)
  for p in problems:
    print(f"  {p}", file=sys.stderr)
  print(
    "\nShip it from the distro's debian/ packaging so dpkg owns it, or record it\nin this test "
    "with the reason it cannot be packaged.",
    file=sys.stderr,
  )
  sys.exit(1)
PYTHON

pass "no Omarchy script writes a path under /usr that no package owns"
