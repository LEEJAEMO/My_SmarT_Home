"""Offline syntax / reference checks. Does not contact HA or any appliance."""
import json
from pathlib import Path
import py_compile
import sys

import jinja2
import yaml

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tests'))
from test_safety import HALoader, walk


def main():
    files = [p for p in ROOT.rglob('*') if p.is_file() and not any(part in ('.git', '.venv', '__pycache__') for part in p.relative_to(ROOT).parts)]
    counts = {'python': 0, 'yaml': 0, 'json': 0, 'templates': 0}
    env = jinja2.Environment()
    for path in files:
        if path.suffix == '.py':
            py_compile.compile(str(path), doraise=True)
            counts['python'] += 1
        elif path.suffix == '.json':
            json.loads(path.read_text(encoding='utf-8-sig'))
            counts['json'] += 1
        elif path.name.endswith(('.yaml', '.yml', '.yaml.example', '.yml.example')):
            value = yaml.load(path.read_text(encoding='utf-8-sig'), Loader=HALoader)
            counts['yaml'] += 1
            for node in walk(value):
                for item in node.values():
                    if isinstance(item, str) and ('{{' in item or '{%' in item):
                        env.parse(item)
                        counts['templates'] += 1
    print('PASS syntax:', counts)
    print('HA runtime config check and real frontend/device tests are separate deployment gates.')


if __name__ == '__main__':
    main()
