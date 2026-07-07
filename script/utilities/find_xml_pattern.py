#!/usr/bin/env python3

"""Find XML elements matching an XPath-like pattern in PreTeXt source files."""

import argparse
import sys
from pathlib import Path

from lxml import etree


XML_SUFFIXES = {".xml", ".ptx"}


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def default_search_root() -> Path:
    return repo_root() / "examples"


def normalize_query(query: str) -> str:
    stripped = query.lstrip()
    if stripped.startswith(("/", ".", "@", "(")):
        return query
    return ".//" + query


def iter_source_files(search_root: Path):
    for path in sorted(search_root.rglob("*")):
        if path.is_file() and path.suffix.lower() in XML_SUFFIXES:
            yield path


def load_source(path: Path):
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        raise ValueError(f"{path}: not valid UTF-8") from exc

    parser = etree.XMLParser(recover=False, huge_tree=True)
    try:
        tree = etree.fromstring(text.encode("utf-8"), parser=parser)
    except etree.XMLSyntaxError as exc:
        raise ValueError(f"{path}: {exc.msg}") from exc

    return text.splitlines(), tree


def line_text(lines, line_number: int) -> str:
    if 1 <= line_number <= len(lines):
        return lines[line_number - 1].rstrip("\r\n")
    return ""


def find_matches(path: Path, query: str, verbose: bool):
    try:
        lines, root = load_source(path)
    except ValueError as exc:
        if verbose:
            print(f"warning: {exc}", file=sys.stderr)
        return []

    xpath = normalize_query(query)
    try:
        matches = root.xpath(xpath)
    except etree.XPathError as exc:
        raise ValueError(f"invalid XPath expression {query!r}: {exc}") from exc

    seen = set()
    results = []
    for match in matches:
        if not isinstance(match, etree._Element):
            continue

        line_number = match.sourceline
        if line_number is None:
            continue

        unique_key = (line_number, root.getroottree().getpath(match))
        if unique_key in seen:
            continue
        seen.add(unique_key)

        results.append((line_number, line_text(lines, line_number)))

    return results


def parse_args():
    parser = argparse.ArgumentParser(
        description="Find XML elements that match an XPath-like pattern in PreTeXt examples."
    )
    parser.add_argument(
        "pattern",
        help="XPath fragment to search for. Relative fragments are matched anywhere in each file.",
    )
    parser.add_argument(
        "--root",
        default=str(default_search_root()),
        help="Directory to search recursively. Defaults to the repository examples directory.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show skipped-file warnings and pattern errors.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    search_root = Path(args.root)

    if not search_root.is_dir():
        if args.verbose:
            print(f"error: search root does not exist or is not a directory: {search_root}", file=sys.stderr)
        return 2

    total_hits = 0
    for path in iter_source_files(search_root):
        try:
            hits = find_matches(path, args.pattern, args.verbose)
        except ValueError as exc:
            if args.verbose:
                print(f"error: {exc}", file=sys.stderr)
            return 2
        if not hits:
            continue

        try:
            display_path = path.relative_to(repo_root())
        except ValueError:
            display_path = path

        for line_number, text in hits:
            total_hits += 1
            print(f"{display_path}:{line_number}: {text}")

    return 0 if total_hits else 1


if __name__ == "__main__":
    raise SystemExit(main())