from pathlib import Path
from datetime import date

root = Path(__file__).resolve().parents[1]
log_dir = root / 'memory' / 'session_logs'
log_dir.mkdir(parents=True, exist_ok=True)
path = log_dir / f'{date.today().isoformat()}.md'
if not path.exists():
    path.write_text(f, encoding='utf-8')
print(path)
