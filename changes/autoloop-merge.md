---
type: major
---
loop-init 與 loop-run 合併為單一 skill `autoloop`（`/autoloop init`、`/autoloop run`）；執行檔全部住在 skill 的 assets/，移除 `~/.claude/loop/` 執行期副本；repo 裡的 `scripts/harness/run-round.sh` 改成永不改變的兩行 stub（只帶 major），版本核對只比 stub 的 major；tag 改為 `autoloop-vX.Y.Z`。既有 repo 需重跑 `/autoloop init`
