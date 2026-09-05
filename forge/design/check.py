#!/usr/bin/env python3
"""forge design check -- the C2 checkpoint's four deterministic checks, static half.

Runs over fathom.html with no browser:
  1. every colour literal in the stylesheet is a token defined on :root
     (every line traceable to a token);
  2. zero tinted neutrals: every token named as a neutral (--bg-*, --fg-*, --line)
     has channel spread < 8;
  3. <= 6 type styles: distinct (font-size, font-weight) pairs the stylesheet can
     produce, counted over the tokens it uses;
  4. the two vendored weights are the only weights referenced.
The runtime half ("no blank or pending band", interaction states by computed
style) is forge/design/probe.js, run in the browser pane.

Exit 0 = OK, 1 = a check failed. Green is one line per check.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BUDGET_TYPE_STYLES = 6
NEUTRAL_SPREAD = 8


def main():
    html = (ROOT / "fathom.html").read_text()
    css = html[html.index("<style>") + 7: html.index("</style>")]
    root = re.search(r":root\s*\{(.*?)\}", css, re.S).group(1)
    tokens = dict(re.findall(r"(--[\w-]+):\s*([^;]+);", root))
    fails = []

    # 1. colour literals outside :root must not exist
    # (@font-face blocks define the faces -- their literal weights are the
    #  shipped faces themselves, checked in 4, not styles applied to text)
    body = re.sub(r"@font-face\s*\{[^}]*\}", "", css.replace(root, ""))
    literals = re.findall(r"#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(", body)
    if literals:
        fails.append(f"colour literals outside :root: {sorted(set(literals))}")
    print(f"{'FAIL' if literals else 'OK  '} 1 every colour is a token   ({len(tokens)} tokens on :root, {len(literals)} stray literals)")

    # 2. neutrals are neutral
    tinted = []
    for name, val in tokens.items():
        if re.match(r"--(bg|fg|line)", name) and re.match(r"#[0-9a-fA-F]{6}$", val.strip()):
            r, g, b = (int(val.strip()[i:i + 2], 16) for i in (1, 3, 5))
            if max(r, g, b) - min(r, g, b) >= NEUTRAL_SPREAD:
                tinted.append(f"{name}={val.strip()} spread {max(r, g, b) - min(r, g, b)}")
    if tinted:
        fails.append(f"tinted neutrals: {tinted}")
    print(f"{'FAIL' if tinted else 'OK  '} 2 zero tinted neutrals       ({sum(1 for n in tokens if re.match(r'--(bg|fg|line)', n))} neutral tokens, spread < {NEUTRAL_SPREAD})")

    # 3. type styles: (size, weight) pairs reachable from the stylesheet
    sizes = set(re.findall(r"var\((--fs-\d)\)", body))
    weights = set(re.findall(r"var\((--w-[a-z]+)\)", body))
    literal_sizes = re.findall(r"font-size:\s*(\d+px)", body)
    literal_weights = re.findall(r"font-weight:\s*(\d{3})", body)
    if literal_sizes or literal_weights:
        fails.append(f"literal type values outside tokens: sizes {literal_sizes}, weights {literal_weights}")
    styles = len(sizes) * len(weights)
    if styles > BUDGET_TYPE_STYLES:
        fails.append(f"{styles} type styles reachable (> {BUDGET_TYPE_STYLES})")
    print(f"{'FAIL' if styles > BUDGET_TYPE_STYLES or literal_sizes or literal_weights else 'OK  '} 3 <= {BUDGET_TYPE_STYLES} type styles           ({len(sizes)} sizes x {len(weights)} weights = {styles} reachable)")

    # 4. weights referenced are the weights shipped
    faces = set(re.findall(r"@font-face\s*\{[^}]*font-weight:\s*(\d{3})", css))
    used = {tokens[w].strip() for w in weights if w in tokens}
    missing = used - faces
    if missing:
        fails.append(f"weights used but not shipped: {missing}")
    print(f"{'FAIL' if missing else 'OK  '} 4 weights shipped = used     (faces {sorted(faces)}, used {sorted(used)})")

    for f in fails:
        print("  -", f)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
