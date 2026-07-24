#!/usr/bin/env python3
"""Resolves (downloading if necessary) a pinned Godot version and its export templates,
then runs addons/gdpractice/export_packs.gd against the project.

Godot binary resolution order:
    1. `godot` on PATH -- used as-is if its version matches GODOT_VERSION.
       If it's a *different* version, a warning is printed and it is NOT used;
       we fall through to steps 2/3 instead, so a mismatched PATH install can't
       silently reintroduce a version-mismatch bug.
    2. A previously downloaded copy in this script's cache directory
       (~/.godot_versions/<GODOT_VERSION>/).
    3. Downloaded fresh from the official godotengine/godot GitHub release for
       GODOT_VERSION, into that same cache directory.

Export templates are checked against (and installed into) based on system-standard
per-OS directories.

Dependencies:
    pip install certifi


"""

import argparse
import hashlib
import platform
import shutil
import ssl
import stat
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path

import certifi

# Set up logging package:
import logging
log = logging.getLogger('ptxlogger')


def _update_version(version: str):
    global GODOT_VERSION
    global GODOT_VERSION_TAG
    global GODOT_TEMPLATE_VERSION_STRING
    global CACHE_DIR
    global GITHUB_RELEASE_BASE
    GODOT_VERSION = version
    GODOT_VERSION_TAG = "{}-stable".format(GODOT_VERSION)
    # Matches the "major.minor.patch.status" format Godot itself uses for the
    # export-templates directory name (e.g. "4.6.3.stable").
    GODOT_TEMPLATE_VERSION_STRING = "{}.stable".format(GODOT_VERSION)
    CACHE_DIR = Path.home() / ".godot_versions" / GODOT_VERSION

    GITHUB_RELEASE_BASE = "https://github.com/godotengine/godot/releases/download/{}".format(GODOT_VERSION_TAG)



# Built from certifi's CA bundle rather than relying on the system/Python installation's
# own certificate store, since python.org-installed Python on macOS in particular often
# has no certificates configured out of the box, causing CERTIFICATE_VERIFY_FAILED.
_SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())


def _asset_name_for_platform() -> str:
    system = platform.system()
    machine = platform.machine().lower()

    if system == "Darwin":
        return "Godot_v{}_macos.universal.zip".format(GODOT_VERSION_TAG)
    elif system == "Linux":
        arch = "arm64" if machine in ("aarch64", "arm64") else "x86_64"
        return "Godot_v{}_linux.{}.zip".format(GODOT_VERSION_TAG,arch)
    elif system == "Windows":
        return "Godot_v{}_win64.exe.zip".format(GODOT_VERSION_TAG)
    else:
        raise RuntimeError("Unsupported platform: {}".format(system))


def _export_templates_asset_name() -> str:
    return "Godot_v{}_export_templates.tpz".format(GODOT_VERSION_TAG)


def _template_install_dir() -> Path:
    system = platform.system()
    if system == "Linux":
        return Path.home() / ".local/share/godot/export_templates" / GODOT_TEMPLATE_VERSION_STRING
    elif system == "Darwin":
        return Path.home() / "Library/Application Support/Godot/export_templates" / GODOT_TEMPLATE_VERSION_STRING
    elif system == "Windows":
        import os
        return Path(os.environ["APPDATA"]) / "Godot/export_templates" / GODOT_TEMPLATE_VERSION_STRING
    else:
        raise RuntimeError("Unsupported platform: {}".format(system))


def _download(url: str, destination: Path) -> None:
    log.info("Downloading {} ...".format(url))
    destination.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url, context=_SSL_CONTEXT) as response, open(destination, "wb") as out_file:
        shutil.copyfileobj(response, out_file)


# Cache of parsed "filename -> sha512 hex digest" dicts, keyed by GODOT_VERSION_TAG,
# so a single run doesn't re-download SHA512-SUMS.txt once per asset.
_SUMS_CACHE: dict[str, dict[str, str]] = {}


def _get_release_sums() -> dict[str, str]:
    """Downloads and parses the release's SHA512-SUMS.txt (filename -> hex digest).

    Godot publishes this file alongside every stable release's assets, in the
    standard `sha512sum`-compatible format: "<hex digest>  <filename>" per line.
    """
    if GODOT_VERSION_TAG in _SUMS_CACHE:
        return _SUMS_CACHE[GODOT_VERSION_TAG]

    sums_path = CACHE_DIR / "SHA512-SUMS.txt"
    _download("{}/SHA512-SUMS.txt".format(GITHUB_RELEASE_BASE), sums_path)

    sums: dict[str, str] = {}
    for line in sums_path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        # Format is "<digest>  <filename>" (two spaces, or one with some tools);
        # a leading "*" before the filename indicates binary mode and is stripped.
        parts = line.split(None, 1)
        if len(parts) != 2:
            continue
        digest, filename = parts
        filename = filename.lstrip("*")
        sums[filename] = digest.lower()

    sums_path.unlink()
    _SUMS_CACHE[GODOT_VERSION_TAG] = sums
    return sums


def _verify_checksum(file_path: Path, asset_name: str) -> None:
    """Verifies file_path's SHA-512 digest against the release's published sums.

    Raises RuntimeError (and deletes the offending file) on a missing entry or
    a mismatch, so a corrupted or tampered download can never silently proceed
    to extraction/installation.
    """
    sums = _get_release_sums()
    expected = sums.get(asset_name)
    if expected is None:
        file_path.unlink(missing_ok=True)
        raise RuntimeError(
            "No checksum entry for '{}' in {}'s SHA512-SUMS.txt; ".format(asset_name,GODOT_VERSION_TAG) +
            "refusing to use this download."
        )

    hasher = hashlib.sha512()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            hasher.update(chunk)
    actual = hasher.hexdigest()

    if actual != expected:
        file_path.unlink(missing_ok=True)
        raise RuntimeError(
            "Checksum mismatch for '{}': expected {}, got {}. ".format(asset_name,expected,actual) +
            "The downloaded file was deleted; it may be corrupted or tampered with."
        )

    log.info("Checksum verified for {}.".format(asset_name))


def _get_godot_version(godot_path: str) -> str | None:
    try:
        result = subprocess.run([godot_path, "--version"], capture_output=True, text=True, timeout=15)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    # Godot's --version output looks like "4.6.3.stable.official.7d41c59c4"
    return result.stdout.strip()


def _cached_binary_path() -> Path | None:
    system = platform.system()
    if system == "Darwin":
        candidate = CACHE_DIR / "Godot.app/Contents/MacOS/Godot"
    elif system == "Windows":
        candidate = CACHE_DIR / "Godot_v{}_win64.exe".format(GODOT_VERSION_TAG)
    else:
        candidate = CACHE_DIR / "Godot_v{}_linux.x86_64".format(GODOT_VERSION_TAG)
    return candidate if candidate.exists() else None


def _download_and_extract_godot() -> Path:
    asset_name = _asset_name_for_platform()
    zip_path = CACHE_DIR / asset_name
    _download("{}/{}".format(GITHUB_RELEASE_BASE,asset_name), zip_path)
    _verify_checksum(zip_path, asset_name)

    log.info("Extracting {} ...".format(zip_path))
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(CACHE_DIR)
    zip_path.unlink()

    binary_path = _cached_binary_path()
    if binary_path is None:
        raise RuntimeError(
            "Extracted {} but couldn't locate the Godot executable under {}. ".format(asset_name,CACHE_DIR) +
            "The archive's internal layout may not match what this script expects -- check its contents manually."
        )

    if platform.system() != "Windows":
        binary_path.chmod(binary_path.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)

    return binary_path


def resolve_godot(gd_cmd : str, version: str) -> str:
    _update_version(version)
    path_godot = shutil.which(gd_cmd)
    if path_godot is not None:
        version_string = _get_godot_version(path_godot)
        if version_string is not None and version_string.startswith(GODOT_VERSION):
            log.info("Using Godot on PATH ({}, version {}).".format(path_godot,version_string))
            return path_godot
        else:
            log.info(
                "WARNING: 'godot' on PATH is version '{}', ".format(version_string) +
                "not the pinned version '{}'. Ignoring it and using a ".format(GODOT_VERSION) +
                "separately managed copy of {} instead.".format(GODOT_VERSION)
            )

    cached = _cached_binary_path()
    if cached is not None:
        log.info("Using cached Godot {} at {}.".format(GODOT_VERSION,cached))
        return str(cached)

    log.info("Godot {} not found on PATH or in cache; downloading...".format(GODOT_VERSION))
    return str(_download_and_extract_godot())


def ensure_export_templates(version: str) -> None:
    _update_version(version)
    template_dir = _template_install_dir()
    if template_dir.exists() and any(template_dir.iterdir()):
        log.info("Export templates for {} already installed at {}.".format(GODOT_VERSION,template_dir))
        return

    asset_name = _export_templates_asset_name()
    tpz_path = CACHE_DIR / asset_name
    _download("{}/{}".format(GITHUB_RELEASE_BASE,asset_name), tpz_path)
    _verify_checksum(tpz_path, asset_name)

    log.info("Installing export templates to {} ...".format(template_dir))
    template_dir.mkdir(parents=True, exist_ok=True)
    # .tpz files are zip archives with a top-level "templates/" folder; Godot expects
    # the version directory's contents to be the files *inside* that folder, not the
    # folder itself.
    with zipfile.ZipFile(tpz_path) as zf:
        for member in zf.namelist():
            if not member.startswith("templates/") or member == "templates/":
                continue
            relative_path = member[len("templates/"):]
            target_path = template_dir / relative_path
            if member.endswith("/"):
                target_path.mkdir(parents=True, exist_ok=True)
                continue
            target_path.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(member) as source, open(target_path, "wb") as out_file:
                shutil.copyfileobj(source, out_file)
    tpz_path.unlink()
