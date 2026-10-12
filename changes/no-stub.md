---
type: major
---
repo 裡不再放 stub：`/autoloop run` 直接呼叫 skill 的 `run-round.sh`；`init` 改寫 `.claude/autoloop.json`（版本與 assets 路徑）與允許規則 `Bash(<assets>/run-round.sh *)`（已驗證 `~/` 開頭的規則能匹配），並清掉舊的 `scripts/harness/run-round.sh`
