# Changelog

## loop-version 1.1.0 — 2026-10-12 (minor)

- (patch) loop-run：NEEDS-USER 的 OPEN 偵測改為不依賴標題格式（同時支援 `### … — OPEN — AUTH` 與 `## … — OPEN · AUTH · blocks:` 等寫法），避免在不同 repo 誤開實作輪
- (minor) 版本改為 semver：loop-run 開場比對 skill 與共用層版本並自動同步 `~/.claude/loop/`，只對 repo 的 run-round.sh 比 major；minor／patch 發布後不再需要重跑 /loop-init


## loop-version 1.0.0 — 2026-10-12 (initial)

第一版。`loop-init`（建 harness、裝執行器、瘦身指令檔、維護 `~/.claude/loop/`）與 `loop-run`（主 session 迴圈、Fable 決策輪／Opus 實作輪、通知與停止規則、版本核對）。

版本機制：單一來源 `assets/VERSION`，`run-round.sh` 以 `@VERSION@` 佔位、`/loop-init` 安裝時填入，`loop-run` 自有 `VERSION` 檔；`changes/` + `tools/release.sh` 負責升版，`tools/check.sh` 要求 skills 改動必附 change 檔，GitHub Actions 跑 check。

在 `tests/loop/harness` 驗證過的情境：正常實作輪、殘留程序清理、逾時整組殺、Fable 決策輪（TECH 自決／AUTH 留 OPEN）、STOP 檔、並行拒絕、RESOLVED→APPLIED、背景輪結束喚醒主 session、TaskStop 中斷、上下文百分比、手機推播。在正式 repo（threejs-character）跑了 9 輪。
