#!/usr/bin/env bash
# Validate a .drawio file before delivering it.
#
# Usage: validate-drawio.sh <file.drawio> [more.drawio ...]
#
# Checks, in order:
#   1. XML well-formedness
#   2. No XML comments (forbidden in generated diagrams)
#   3. XSD conformance against references/mxfile.xsd (full <mxfile> form only)
#   4. Structural cell rules: root cells present, unique ids, edges have an mxGeometry child,
#      every parent reference resolves
#   5. AWS shape names: every resIcon / shape=mxgraph.aws4.* / grIcon exists in the official index
#   6. Style hygiene: no gradientColor (legacy AWS palette), html=1 present
#
# Exit code 0 = all files pass, 1 = at least one failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REF_DIR="$(cd "$SCRIPT_DIR/../references" && pwd)"
XSD="$REF_DIR/mxfile.xsd"
RESICONS="$REF_DIR/valid-aws4-resicons.tsv"
SHAPES="$REF_DIR/valid-aws4-shapes.tsv"
# NB: do not name this GROUPS - that is a bash special variable (array of group IDs).
GROUPICONS="$REF_DIR/valid-aws4-groups.tsv"

if [ "$#" -eq 0 ]; then
  echo "usage: $(basename "$0") <file.drawio> [...]" >&2
  exit 2
fi

fail_total=0

for FILE in "$@"; do
  echo "=== $FILE"
  if [ ! -f "$FILE" ]; then
    echo "  FAIL  file not found"
    fail_total=$((fail_total + 1))
    continue
  fi

  failed=0

  # 1. well-formedness
  if command -v xmllint >/dev/null 2>&1; then
    if xmllint --noout "$FILE" 2>/tmp/_dio_wf.txt; then
      echo "  ok    XML well-formed"
    else
      echo "  FAIL  XML not well-formed:"
      sed 's/^/          /' /tmp/_dio_wf.txt
      failed=1
    fi
  else
    echo "  skip  xmllint not installed (well-formedness, XSD)"
  fi

  # 2. no comments
  if grep -q '<!--' "$FILE"; then
    echo "  FAIL  contains XML comments (forbidden)"
    failed=1
  else
    echo "  ok    no XML comments"
  fi

  # 3. XSD
  if command -v xmllint >/dev/null 2>&1 && [ -f "$XSD" ]; then
    if xmllint --noout --schema "$XSD" "$FILE" >/dev/null 2>/tmp/_dio_xsd.txt; then
      echo "  ok    XSD valid"
    else
      echo "  FAIL  XSD invalid:"
      grep -v 'validates$' /tmp/_dio_xsd.txt | sed 's/^/          /'
      failed=1
    fi
  fi

  # 4/5/6. structural + shape-name + style checks
  if python3 - "$FILE" "$RESICONS" "$SHAPES" "$GROUPICONS" <<'PY'
import re, sys, xml.etree.ElementTree as ET

path, resicons_path, shapes_path, groups_path = sys.argv[1:5]
problems = []
notes = []

def load(p):
    names = set()
    try:
        with open(p) as fh:
            for line in fh:
                if line.startswith('#') or not line.strip():
                    continue
                names.add(line.split('\t')[0])
    except OSError:
        return None
    return names

valid_res = load(resicons_path)
valid_shape = load(shapes_path)
valid_group = load(groups_path)

raw = open(path, encoding='utf-8').read()
try:
    root = ET.fromstring(raw)
except ET.ParseError as e:
    print(f"  FAIL  parse error: {e}")
    sys.exit(1)

cells = root.findall('.//mxCell')
objects = root.findall('.//object') + root.findall('.//UserObject')

# --- root cells
ids = []
for c in cells:
    cid = c.get('id')
    if cid is not None:
        ids.append(cid)
for o in objects:
    if o.get('id') is not None:
        ids.append(o.get('id'))

if '0' not in ids or '1' not in ids:
    problems.append("missing mandatory root cells id=\"0\" and/or id=\"1\"")

# --- duplicate ids
dupes = {i for i in ids if ids.count(i) > 1}
if dupes:
    problems.append(f"duplicate ids: {sorted(dupes)}")

# --- edges must have an mxGeometry child
for c in cells:
    if c.get('edge') == '1':
        if c.find('mxGeometry') is None:
            problems.append(f"edge id={c.get('id')!r} has no <mxGeometry> child (will not render)")
        if c.get('vertex') == '1':
            problems.append(f"cell id={c.get('id')!r} is both vertex and edge")

# --- parent references resolve
known = set(ids)
for c in cells:
    p = c.get('parent')
    if p is not None and p not in known:
        problems.append(f"cell id={c.get('id')!r} has parent={p!r} which does not exist")

# --- AWS shape names
def styles():
    for c in cells:
        yield c.get('id'), c.get('style') or ''
    for o in objects:
        mc = o.find('mxCell')
        if mc is not None:
            yield o.get('id'), mc.get('style') or ''

aws_checked = 0
for cid, st in styles():
    for name in re.findall(r'resIcon=mxgraph\.aws4\.([A-Za-z0-9_]+)', st):
        aws_checked += 1
        if valid_res is not None and name not in valid_res:
            problems.append(f"cell id={cid!r}: resIcon 'mxgraph.aws4.{name}' is not in the official "
                            f"shape index - either a typo (renders as a blank square) or an "
                            f"undocumented legacy alias; use the name from valid-aws4-resicons.tsv")
    for name in re.findall(r'grIcon=mxgraph\.aws4\.([A-Za-z0-9_]+)', st):
        aws_checked += 1
        if valid_group is not None and name not in valid_group:
            problems.append(f"cell id={cid!r}: grIcon 'mxgraph.aws4.{name}' is not a valid group "
                            f"icon; see valid-aws4-groups.tsv")
    for name in re.findall(r'(?<!res)(?<!gr)(?<!pr)shape=mxgraph\.aws4\.([A-Za-z0-9_]+)', st):
        if name in ('resourceIcon', 'productIcon', 'group'):
            continue
        aws_checked += 1
        if valid_shape is not None and name not in valid_shape:
            problems.append(f"cell id={cid!r}: shape 'mxgraph.aws4.{name}' is not a valid shape name")

# --- style hygiene
grad = [cid for cid, st in styles() if re.search(r'gradientColor=#', st)]
if grad:
    problems.append(f"legacy gradient palette on cells {grad[:6]} - current AWS icons are flat "
                    f"(use gradientColor=none)")

nohtml = [cid for cid, st in styles()
          if st and 'html=1' not in st and 'shape=' in st]
if nohtml:
    notes.append(f"cells without html=1: {nohtml[:6]}")

# --- literal \n in labels
for c in cells:
    v = c.get('value') or ''
    if '\\n' in v:
        problems.append(f"cell id={c.get('id')!r} label contains literal \\n (use &#xa;)")

missing = [p for p, v in (('valid-aws4-resicons.tsv', valid_res),
                          ('valid-aws4-shapes.tsv', valid_shape),
                          ('valid-aws4-groups.tsv', valid_group)) if v is None]
if missing:
    problems.append(f"reference list(s) not readable: {missing} - shape names could NOT be "
                    f"validated, so this result is not trustworthy")

for n in notes:
    print(f"  note  {n}")

if problems:
    for p in problems:
        print(f"  FAIL  {p}")
    sys.exit(1)

print(f"  ok    structure, parents, edge geometry")
print(f"  ok    {aws_checked} AWS shape name(s) valid")
print(f"  ok    style hygiene")
sys.exit(0)
PY
  then :; else failed=1; fi

  if [ "$failed" -eq 0 ]; then
    echo "  PASS"
  else
    echo "  --> FAILED"
    fail_total=$((fail_total + 1))
  fi
done

rm -f /tmp/_dio_wf.txt /tmp/_dio_xsd.txt

if [ "$fail_total" -gt 0 ]; then
  echo
  echo "$fail_total file(s) failed validation."
  exit 1
fi
echo
echo "All files passed."
