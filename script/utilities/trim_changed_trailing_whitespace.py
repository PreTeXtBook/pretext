#!/usr/bin/env python3

# Usage:
#   script/utilities/trim_changed_trailing_whitespace.py [--base <ref>] [--check]
# This script identifies lines with trailing whitespace that have been
# changed in the current branch compared to a specified base.
# By default, it compares against the merge-base with the upstream branch or origin/HEAD.
# With --check, it reports the files and line counts without modifying them,
# exiting non-zero if any are found.

import argparse
import re
import subprocess
import sys
from pathlib import Path

HUNK_RE = re.compile(r"^@@ -(?:\d+)(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


def run_git(args):
    result = subprocess.run(
        ["git", *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def resolve_default_base():
    try:
        upstream = run_git(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"])
        return run_git(["merge-base", "HEAD", upstream])
    except subprocess.CalledProcessError:
        pass

    try:
        remote_head = run_git(["symbolic-ref", "refs/remotes/origin/HEAD"])
        return run_git(["merge-base", "HEAD", remote_head])
    except subprocess.CalledProcessError as exc:
        raise SystemExit(
            "Unable to determine a base ref. Use --base to specify one explicitly."
        ) from exc


def changed_lines(base_ref):
    diff_output = run_git(
        ["-c", "core.quotePath=false",
         "diff", "--unified=0", "--no-color", "--no-ext-diff", base_ref, "--"]
    )
    files = {}
    current_file = None

    for line in diff_output.splitlines():
        if line.startswith("+++ b/"):
            file_name = line[6:]
            current_file = None if file_name == "/dev/null" else file_name
            if current_file is not None:
                files.setdefault(current_file, set())
            continue

        if current_file is None:
            continue

        match = HUNK_RE.match(line)
        if not match:
            continue

        start = int(match.group(1))
        count = int(match.group(2) or "1")
        if count == 0:
            continue

        files[current_file].update(range(start, start + count))
    return files


def process_file(file_path, line_numbers, fix):
    # Return the changed line numbers that have trailing whitespace, in order.
    # When fix is True, also rewrite the file with those lines trimmed,
    # preserving each line's original ending. Files that are missing, binary,
    # or not valid UTF-8 are skipped (treated as having no offending lines).
    path = Path(file_path)
    if not path.is_file():
        return []

    raw = path.read_bytes()
    if b"\0" in raw:
        return []
    try:
        content = raw.decode("utf-8")
    except UnicodeDecodeError:
        return []

    lines = content.splitlines(keepends=True)
    hits = []

    for line_number in sorted(line_numbers):
        index = line_number - 1
        if not 0 <= index < len(lines):
            continue

        original = lines[index]
        for ending in ("\r\n", "\n", "\r"):
            if original.endswith(ending):
                body = original[: -len(ending)]
                break
        else:
            ending = ""
            body = original

        trimmed = body.rstrip(" \t") + ending
        if trimmed != original:
            hits.append(line_number)
            lines[index] = trimmed

    if fix and hits:
        path.write_text("".join(lines), encoding="utf-8", newline="")

    return hits


def parse_args():
    parser = argparse.ArgumentParser(
        description="Trim trailing spaces and tabs on lines changed in the current branch diff."
    )
    parser.add_argument(
        "--base",
        help="Base ref or commit to diff against. Defaults to the merge-base with upstream or origin/HEAD.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Report files and line counts without modifying them.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    base_ref = args.base or resolve_default_base()
    files_to_lines = changed_lines(base_ref)

    if not files_to_lines:
        print("No changed lines found.")
        return 0

    total_lines = 0
    changed_files = 0

    for file_path in sorted(files_to_lines):
        hits = process_file(file_path, files_to_lines[file_path], fix=not args.check)
        if not hits:
            continue

        changed_files += 1
        total_lines += len(hits)
        if args.check:
            print(f"{file_path}: {len(hits)} line(s) with trailing whitespace")
            print(f"  line numbers: {', '.join(str(n) for n in hits)}")
        else:
            print(f"Trimmed {len(hits)} line(s) in {file_path}")

    if total_lines == 0:
        print("No trailing whitespace found on changed lines.")
        return 0

    action = "Found" if args.check else "Trimmed"
    print(f"{action} trailing whitespace on {total_lines} line(s) across {changed_files} file(s).")
    return 1 if args.check else 0


if __name__ == "__main__":
    sys.exit(main())
