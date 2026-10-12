# autoloop 測試情境

測試床：`tests/loop/harness/`。用法：複製到一個空資料夾（例如 `~/relay-test`），`git init`，commit，然後在該資料夾跑 `/autoloop init` 裝 stub（或手動：`A=~/.claude/skills/autoloop/assets; sed "s/@VERSION@/$(cat $A/VERSION)/" $A/run-round-stub.sh > scripts/harness/run-round.sh && chmod +x scripts/harness/run-round.sh`），再逐項跑下面的情境。工作者用 Sonnet 可以省錢：`bash scripts/harness/run-round.sh opus --model claude-sonnet-5-5 --effort medium --budget 2`。要試還沒發布的 prompt，用 `--prompt <repo 裡的 decide.md 或 implement.md>`。

| # | 情境 | 怎麼做 | 預期 |
|---|---|---|---|
| 1 | 正常實作輪 | `run-round.sh opus`（T-01） | exit 0、`LOOP-STATUS: CONTINUE`、commit + 切片記錄、PLAN 標 DONE、`.loop.lock` 消失、log 在 repo 的 `logs/loop/` |
| 2 | 殘留程序 | 先在資料夾起一個獨立程序群組的 `sleep 3500`，再 `run-round.sh sweep` | `killed=[<pid>(sleep_3500)]`，呼叫端 shell 不受影響 |
| 3 | 逾時 | `run-round.sh opus --timeout 60`（T-03，gate 卡 10 分鐘） | exit 124、`sleep 600` 消失、lock 移除、摘要 `TIMEOUT` |
| 4 | 決策輪 TECH | NEEDS-USER 加一個 OPEN TECH 項目，`run-round.sh fable` | 項目改 RESOLVED、決定寫進 PLAN、純文件 commit、STOP 移除 |
| 5 | 決策輪 AUTH | 加一個 OPEN AUTH 項目（例如刪已追蹤檔） | 留 OPEN、加 supervisor 建議、`LOOP-STATUS: ASK_USER` |
| 6 | STOP 檔 | `touch STOP` 再 `run-round.sh opus` | 工作者不寫任何檔，`LOOP-STATUS: STOPPED` |
| 7 | 並行 | 兩個 `run-round.sh` 幾乎同時啟動 | 第二個 exit 75 `BUSY` |
| 8 | RESOLVED→APPLIED | 把 AUTH 項目填好決定改 RESOLVED，`run-round.sh opus` | 下一輪改 APPLIED 並照決定做切片 |
| 9 | 背景喚醒 | 主 session 以背景 Bash 跑 `run-round.sh` | 結束時主 session 被自動叫醒 |
| 10 | 中斷 | 背景跑 T-07（gate 卡住），`TaskStop` | 工作者與 gate 全部消失、lock 釋放、摘要 `INTERRUPTED` |
| 11 | 版本核對 | 把 stub 的 `version X.Y.Z` 改成別的（只改 patch 也算），`/autoloop run` | 拒絕啟動，只提示 `/autoloop init`，不自己改 stub |
| 16 | repo 層安裝 | 把 skill 複製到 `<repo>/.claude/skills/autoloop/`，暫時移走 `~/.claude/skills/autoloop`，跑 `run-round.sh sweep` | stub 從 repo 層找到 runner，正常執行 |
| 12 | 上下文停止 | 主 session 先讀目前百分比，把門檻暫設在它上方一點，跑一輪 | 跨過門檻後通知並停；說「繼續」後每輪摘要帶提醒 |
| 13 | 推播 | 任一停下情境，使用者離開 app | 手機收到通知；人在 app 前只有桌面通知（工具設計） |
| 14 | 接手 | 另開一個 session 在同一資料夾 `/autoloop run` | 看到 `.loop-main.json` 還新，詢問是否接手 |
| 15 | OPEN 偵測格式 | NEEDS-USER 用 `## NU-001 … — OPEN · AUTH · blocks:` 寫法 | 主 session 仍判為有 OPEN、開 fable |
