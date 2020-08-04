#!/usr/bin/env python3
"""
Description:

    Call this script after Github Action: lots0logs/gh-action-get-changed-files

    This script assumes there will be a ${GITHUB_HOME}/files.json containing a list of the changed files.
    This script then determines if there are any go packages affected by the change
    that will require further actions to be taken. Packages without a Makefile are ignored.

    The set of affected go package directories are then sharded by ${NUM_SHARDS}
    and outputted to ${GITHUB_HOME}/dirty_pkgs-{shard}.txt for use in the next CI step.

Sample Usage:
    python find_dirty_pkgs.py \
        ${GITHUB_HOME} ${REPOS_ROOT}/heustics/src ${REPOS_ROOT} ${NUM_SHARDS}
"""
import defopt
import json
import logging
import re
import subprocess
import sys
import os

from typing import Tuple

logger = logging.getLogger(__name__)

# Dirty files matching these regex patterns will be ignored
ignore_dirty_file_patterns = [
    re.compile(r'.*README$'),        # README
    re.compile(r'.*\.md$'),          # Markdown
    re.compile(r'.*LICENSE$'),       # LICENSE
    re.compile(r'.*/docs/.+')        # files in a /docs subfolder
]


def main(github_home: str, src_dir: str, repos_root: str, num_shards: int = 1):
    dirty_dirs = load_dirty_dirs(github_home)
    logger.info(f'Found Dirty dirs: {dirty_dirs}')

    dirty_import_paths = find_dirty_import_paths(dirty_dirs)
    logger.info(f'Found Dirty Import Paths: {dirty_import_paths}')

    dirty_pkgs = find_dirty_pkgs(dirty_import_paths, src_dir, repos_root)
    logger.info(f'Found Dirty Pkgs: {dirty_pkgs}')

    dirty_sharded_pkg_paths = output_dirty_sharded_pkgs(github_home, dirty_pkgs, num_shards)
    logger.info(f'Outputted Dirty Sharded Pkg Paths: {dirty_sharded_pkg_paths}')


def load_dirty_dirs(github_home: str) -> set:
    files_json_path = os.path.join(github_home, 'files.json')

    dirty_dirs = set()
    with open(files_json_path) as f:
        for dirty_file in json.load(f):
            if ignore_dirty_file(dirty_file):
                logger.debug(f'Ignoring dirty file {dirty_file}')
                continue

            # TODO:
            # Test if dirty_file matches against a map of dirty file regex patterns
            # that returns a set of dirty_dirs to add.

            dirname = os.path.dirname(dirty_file)
            if dirname in dirty_dirs:
                continue

            dirty_dirs.add(dirname)

    return dirty_dirs


def ignore_dirty_file(file_path: str) -> bool:
    for p in ignore_dirty_file_patterns:
        if p.match(file_path):
            return True
    return False


def find_dirty_import_paths(dirty_dirs: set) -> set:
    dirty_import_paths = set()
    for dirname in dirty_dirs:
        return_code, stdout, _ = run_cmd_with_output(
            'go', 'list', '-f', '{{ .ImportPath }}',
            f'./{dirname}/...')

        if return_code != 0:
            logger.warn(f'Go list for ImportPath returned error: {return_code}')
            continue

        import_paths = stdout.strip().split('\n')
        if not import_paths:
            continue

        dirty_import_paths.update(import_paths)

    return dirty_import_paths


def find_dirty_pkgs(dirty_import_paths: set, src_dir: str, repos_root: str, ) -> set:
    logger.info(f'Finding dirty pkgs for src_dir: {src_dir}')

    return_code, stdout, _ = run_cmd_with_output(
        'go', 'list', '-f', '{{ .Dir }},{{ .ImportPath }},{{ range .Deps }}{{ . }} {{end}}\n',
        f'{src_dir}/...'
    )
    if return_code != 0:
        raise RuntimeError(f'Find dirty pkgs error: {return_code}')

    dirty_pkgs = set()

    for line in stdout.split('\n'):
        line = line.strip()
        if not line:
            continue

        # pkg_root, import_path, deps
        fields = line.split(',')

        pkg_root = fields[0].strip()
        if not pkg_root:
            continue

        makefile_path = os.path.join(pkg_root, 'Makefile')
        if not os.path.isfile(makefile_path):
            logger.debug(f'Pkg has no Makefile: {pkg_root}')
            continue

        import_path = fields[1].strip()
        if not import_path:
            logger.debug(f'Pkg has no ImportPath: {pkg_root}')
            continue

        deps = set(fields[2].strip().split(' '))
        if not deps:
            logger.debug(f'Pkg has no dependencies: {pkg_root}')
            continue

        deps.add(import_path)

        dirty_deps = deps - dirty_import_paths
        if len(dirty_deps) == len(deps):
            logger.debug(f'Pkg has no dirty dependencies: {pkg_root}')
            continue

        logger.debug(f'Pkg has dirty dependencies: {pkg_root}')

        rel_pkg_path = os.path.relpath(pkg_root, repos_root)
        dirty_pkgs.add(rel_pkg_path)

    return dirty_pkgs


def output_dirty_sharded_pkgs(github_home: str, dirty_pkgs: set, num_shards: int = 1):
    dirty_shard_path_tmpl = os.path.join(github_home, 'dirty_pkgs-{}.txt')

    dirty_sharded_paths = []
    dirty_sharded_files = []
    try:
        for n in range(0, num_shards):
            p = dirty_shard_path_tmpl.format(n)
            f = open(p, 'w')

            dirty_sharded_files.append(f)
            dirty_sharded_paths.append(p)

        for i, pkg in enumerate(dirty_pkgs):
            f = dirty_sharded_files[i % num_shards]
            f.write(f'{pkg}\n')

    finally:
        for f in dirty_sharded_files:
            try:
                f.close()
            except OSError:
                pass

    return dirty_sharded_paths


def run_cmd_with_output(*args: str) -> Tuple[int, str, str]:
    process = subprocess.Popen(
        args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        close_fds=True,
        universal_newlines=True)

    stdout, stderr = process.communicate()

    return process.returncode, stdout, stderr


if __name__ == '__main__':
    logging_level = os.environ.get('LOGGING_LEVEL', 'INFO').upper()
    if logging_level in {'CRITICAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG', 'NOTSET'}:
        logging.basicConfig(stream=sys.stdout, level=logging_level)
        logger = logging.getLogger(os.path.basename(sys.argv[0]))

    try:
        defopt.run(main)
    except Exception:
        logger.exception(f'{__name__} failed')
        raise
