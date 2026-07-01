# Scripts

Helper utilities for session log management.

## Requirements

Both scripts require **Python 3.8 or later**.

Check if Python is installed:
```
python --version
```

If not installed, download from: https://www.python.org/downloads/

**Important:** If Python is not available, use the `/end-session` command instead — the AI coach will produce the session log content for you to paste manually into `memory/session_logs/YYYY-MM-DD.md`.

---

## new_session_log.py

Creates a new dated session log file in `memory/session_logs/`.

**Usage:**
```bash
python scripts/new_session_log.py
```

**Output:** Creates `memory/session_logs/YYYY-MM-DD.md` with a structured template.

---

## weekly_summary.py

Lists the last 7 session logs and prompts you to run `/run-weekly-review`.

**Usage:**
```bash
python scripts/weekly_summary.py
```

---

## PowerShell alternatives (no Python required)

### Create a new session log

```powershell
$date = Get-Date -Format "yyyy-MM-dd"
$logPath = "memory/session_logs/$date.md"

$template = @"
# Session Log — $date

## Topic


## Exercise


## Learner answer summary


## AI feedback


## Score


## Mistakes


## Next action

"@

New-Item -ItemType File -Path $logPath -Force
Set-Content -Path $logPath -Value $template
Write-Host "Created: $logPath"
```

### List recent session logs

```powershell
Get-ChildItem memory/session_logs/*.md |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 7 |
  ForEach-Object { Write-Host $_.Name }
```

Save either snippet as a `.ps1` file and run with:
```
powershell -ExecutionPolicy Bypass -File scripts/your_script.ps1
```
