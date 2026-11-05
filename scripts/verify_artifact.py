"""Verify distributed hashes, anonymous export markers and reported counts."""
from pathlib import Path
import csv
import hashlib
import json
import re
import statistics

ROOT = Path(__file__).resolve().parents[1]
STUDY = ROOT / 'research/estudo_regressoes'


def rows(path):
    with path.open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def main():
    for line in (ROOT / 'SHA256SUMS').read_text().splitlines():
        digest, name = line.split('  ', 1)
        path = ROOT / name
        require(path.is_file(), 'Missing file: ' + name)
        require(hashlib.sha256(path.read_bytes()).hexdigest() == digest,
                'Hash mismatch: ' + name)
    nominal = rows(STUDY / 'runs/nominal/p1p3-20261103/nominal-runs.csv')
    require(len(nominal) == 33, 'Nominal row count changed')
    for st, expected in {'S0': (9298, 9218, 9425),
                         'S1': (9327.5, 9206, 9411),
                         'S2': (9345, 9261, 9565)}.items():
        group = [r for r in nominal if r['strategy'] == st and r['phase'] == 'measured']
        require(len(group) == 10, 'Nominal repetitions changed')
        times = [int(r['duration_ms']) for r in group]
        require((statistics.median(times), min(times), max(times)) == expected,
                'Nominal durations changed')
        require(all(r['classification'] == 'nominal_pass' for r in group),
                'Nominal classification changed')
    variants = rows(STUDY / 'runs/variants/p1p3-20261103/variant-runs.csv')
    expected_ids = {'S0': {'N4', 'N5'}, 'S1': {'N4', 'N5'},
                    'S2': {'N1', 'N2', 'N4', 'N5', 'N6', 'N7', 'N8'}}
    require(len(variants) == 34, 'Variant row count changed')
    for st, ids in expected_ids.items():
        detected = [r for r in variants if r['strategy'] == st and
                    r['classification'] == 'detected_assertion']
        require({r['variant'] for r in detected} == ids, 'Detected identities changed')
        for item in ids:
            require(len([r for r in detected if r['variant'] == item]) == 3,
                    'Variant repetitions changed')
    invalid = [r for r in variants if r['classification'] == 'invalid_variant']
    require(len(invalid) == 1 and invalid[0]['variant'] == 'N3', 'Invalid exclusion changed')
    restorations = rows(STUDY / 'runs/variants/p1p3-20261103/restorations.csv')
    require(len(restorations) == 8 and all(
        r['byte_restored'] == 'True' and r['original_sha256'] == r['restored_sha256']
        and r['sanity_passed'] == '27' for r in restorations), 'Restorations changed')
    gate = rows(STUDY / 'runs/gate/p1p3-20261103/gate-results.csv')
    require({r['variant'] for r in gate if r['outcome'] == 'blocked'} == expected_ids['S2'],
            'Gate decisions changed')
    historical = json.loads((ROOT / 'research/evidencias/mutacoes/resultados.json').read_text())
    valid = [r for r in historical['variants'] if r['eligible']]
    require(len(valid) == 8 and sum(r['baseDetected'] for r in valid) == 3 and
            sum(r['expandedDetected'] for r in valid) == 8, 'Historical results changed')
    matrix = rows(ROOT / 'research/evidencias/matriz_transicoes.csv')
    require(sum(int(r['base_assertions']) for r in matrix) == 8 and
            sum(int(r['expanded_assertions']) for r in matrix) == 12,
            'Historical effect counts changed')
    for path in ROOT.rglob('*'):
        if path.is_file() and path.suffix in {'.json', '.csv', '.txt', '.md', '.dart', '.ps1', '.yml', '.yaml', '.bin', '.patch'}:
            if any(x in path.parts for x in ('.dart_tool', 'build')):
                continue
            text = path.read_text(encoding='utf-8-sig')
            require(not re.search(r'[A-Za-z]:[/\\]+Users[/\\]+(?!reviewer\b)[^/\\\s]+', text),
                    'Personal home path found: ' + path.relative_to(ROOT).as_posix())
            require(not re.search(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----', text),
                    'Private key marker found')
    print('OK: hashes; 33 nominal runs; 11 valid crossings x 3; N3 invalid; '
          '8 restorations; 7 gate blocks; historical results; local path scan.')


if __name__ == '__main__':
    main()
