from pathlib import Path

root = Path(__file__).resolve().parents[1]
logs = sorted((root / 'memory' / 'session_logs').glob('*.md'))
print('# Weekly Summary Source Logs')
for log in logs[-7:]:
    print(f'- {log.name}')
print('\nAsk the AI to read these logs and run /run-weekly-review.')
