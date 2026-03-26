#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
TOP="top"
DEVICE="GW5A-LV25MG121NC1/I0"
FAMILY="GW5A-25A"
CST="fpga/tang_primer_25k.cst"
FREQ_MHZ="50"
REPORT_JSON="${BUILD_DIR}/${TOP}_report.json"
PNR_JSON="${BUILD_DIR}/${TOP}_pnr.json"
SYN_JSON="${BUILD_DIR}/${TOP}.json"

if ! command -v nextpnr-himbaechel >/dev/null 2>&1; then
  echo "Error: nextpnr-himbaechel not found in PATH." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 not found in PATH." >&2
  exit 1
fi

mkdir -p "${BUILD_DIR}"

echo "[1/2] Running synthesis (make synth)..."
(
  cd "${ROOT_DIR}"
  make synth >/dev/null
)

echo "[2/2] Running place-and-route with JSON report..."
(
  cd "${ROOT_DIR}"
  nextpnr-himbaechel \
    --json "${SYN_JSON}" \
    --write "${PNR_JSON}" \
    --report "${REPORT_JSON}" \
    --device "${DEVICE}" \
    --vopt "family=${FAMILY}" \
    --vopt "cst=${CST}" \
    --vopt sspi_as_gpio \
    --freq "${FREQ_MHZ}" \
    >/tmp/${TOP}_utilization_nextpnr.log 2>&1
)

python3 - "${REPORT_JSON}" "${DEVICE}" "${FREQ_MHZ}" <<'PY'
import json
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
device = sys.argv[2]
target_freq = float(sys.argv[3])

if not report_path.exists():
    print(f"Error: report not found: {report_path}", file=sys.stderr)
    sys.exit(1)

with report_path.open("r", encoding="utf-8") as f:
    report = json.load(f)

util = report.get("utilization", {})
fmax = report.get("fmax", {})

if not util:
    print("Error: utilization data not found in report JSON.", file=sys.stderr)
    sys.exit(1)

def pct(used, available):
    return (100.0 * used / available) if available else 0.0

rows = []
for resource, data in util.items():
    used = int(data.get("used", 0))
    available = int(data.get("available", 0))
    rows.append((resource, used, available, pct(used, available)))

rows.sort(key=lambda r: r[3], reverse=True)

important = ["LUT4", "DFF", "ALU", "BSRAM", "IOB", "PLLA"]
important_rows = [r for r in rows if r[0] in important]
other_rows = [r for r in rows if r[0] not in important and r[1] > 0]

peak_resource, peak_used, peak_avail, peak_pct = rows[0]

print("FPGA Utilization Summary")
print("=" * 78)
print(f"Device: {device}")
print(f"Report: {report_path}")
print(f"Peak utilization: {peak_resource} = {peak_used}/{peak_avail} ({peak_pct:.2f}%)")
print()

print("Key resources:")
print(f"{'Resource':<12} {'Used':>8} {'Available':>10} {'Util%':>8}")
print("-" * 42)
for resource, used, available, p in important_rows:
    print(f"{resource:<12} {used:>8} {available:>10} {p:>7.2f}%")

if other_rows:
    print()
    print("Other used resources:")
    print(f"{'Resource':<20} {'Used':>8} {'Available':>10} {'Util%':>8}")
    print("-" * 50)
    for resource, used, available, p in other_rows:
        print(f"{resource:<20} {used:>8} {available:>10} {p:>7.2f}%")

if fmax:
    print()
    print("Clock summary:")
    print(f"{'Clock':<32} {'Achieved MHz':>14} {'Target MHz':>12} {'Status':>8}")
    print("-" * 72)
    for clock, vals in sorted(fmax.items()):
        achieved = float(vals.get("achieved", 0.0))
        constraint = float(vals.get("constraint", target_freq))
        status = "PASS" if achieved >= constraint else "FAIL"
        print(f"{clock:<32} {achieved:>14.2f} {constraint:>12.2f} {status:>8}")

print()
print("Done.")
PY
