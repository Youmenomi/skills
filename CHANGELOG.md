# Changelog

## loop-version 1 — 2026-10-12

第一版。`loop-init`（建 harness、裝執行器、瘦身指令檔、維護 `~/.claude/loop/`）與 `loop-run`（主 session 迴圈、Fable 決策輪／Opus 實作輪、通知與停止規則、版本核對）。

在 `tests/loop/harness` 驗證過的情境：正常實作輪、殘留程序清理、逾時整組殺、Fable 決策輪（TECH 自決／AUTH 留 OPEN）、STOP 檔、並行拒絕、RESOLVED→APPLIED、背景輪結束喚醒主 session、TaskStop 中斷、上下文百分比、手機推播。在正式 repo（threejs-character）跑了 9 輪。
