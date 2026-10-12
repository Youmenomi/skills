# Changelog

## autoloop 2.0.0 — 2026-10-13 (major)

- (major) repo 裡不再放 stub：`/autoloop run` 直接呼叫 skill 的 `run-round.sh`；`init` 改寫 `.claude/autoloop.json`（版本與 assets 路徑）與允許規則 `Bash(<assets>/run-round.sh *)`（已驗證 `~/` 開頭的規則能匹配），並清掉舊的 `scripts/harness/run-round.sh`


## autoloop 1.0.0 — 2026-10-13 (major)

- (major) autoloop 1.0.0 首次正式發布：`/autoloop init`（建 harness／瘦身指令檔／裝 stub／從 1.x 升級清理）與 `/autoloop run`（主 session 迴圈、Fable 決策輪／Opus 實作輪、通知與停止規則）；stub 帶完整版號，run 要求與 skill 完全相同；skill 可裝在使用者層或 repo 層


## autoloop 0.0.0 — 開發中，尚未發布

目前 main 與 dev 上的內容都是 1.0.0 之前的開發版，沒有相容性承諾。1.0.0 之前做過並驗證過的事：

- 架構：主 session 當迴圈（`/autoloop run`），每輪由 repo 的 stub 啟動安裝目錄裡的 `run-round.sh`，開一個獨立的 `claude -p` 工作者（NEEDS-USER 有 OPEN → Fable 決策輪，否則 Opus 實作輪）；工作者有自己的程序群組、逾時、殘留清理；需要人決定或主 session 上下文超過 30% 時推手機通知並停下。
- `/autoloop init`：新 repo 建 harness；已有 harness 的瘦身指令檔；裝 stub、允許規則、ignore；從 1.x（loop-init／loop-run）升級時清掉過時內容。
- 在 `tests/loop/harness` 驗證過：正常輪、殘留清理、逾時整組殺、Fable 決策輪（TECH 自決／AUTH 留 OPEN）、STOP、並行拒絕、RESOLVED→APPLIED、背景輪喚醒主 session、TaskStop 中斷、上下文百分比、手機推播。正式 repo（threejs-character）跑了 9 輪。
- 版本機制：semver，單一來源 `skills/autoloop/assets/VERSION`；`changes/` + `tools/release.sh`；main 永遠是已發布狀態；`/autoloop run` 比對 repo stub 的完整版號，不符就要求重跑 `/autoloop init`。
