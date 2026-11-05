#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

python3 - <<'PY'
import os
from pathlib import Path
import shlex

root = Path(os.environ["ROOT"])

def check(condition, description):
  if not condition:
    raise SystemExit("not ok - " + description)
  print("ok - " + description, flush=True)

drop_in = root / "default/systemd/system/plocate-updatedb.service.d/10-omarchy.conf"
directives = [line.strip() for line in drop_in.read_text().splitlines() if line.strip() and not line.startswith("#")]
check(len(directives) == 3 and directives[:2] == ["[Service]", "ExecStart="] and directives[2].startswith("ExecStart="),
      "locate drop-in replaces the command and preserves upstream service restrictions")
command = shlex.split(directives[2].removeprefix("ExecStart="))
options = ["--prune-bind-mounts=no", "--add-prunepaths=/.snapshots"]
check(command == ["/usr/bin/updatedb", *options],
      "locate service runs updatedb directly with fixed Btrfs options")
PY
