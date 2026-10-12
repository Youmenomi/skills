---
name: loop-run
description: 在已初始化（/loop-init）的 repo 啟動或接續自動開發 loop。本 session 成為主迴圈：每輪用 scripts/harness/run-round.sh 開一個獨立的 claude -p 工作者（有 OPEN 的 NEEDS-USER 項目就開 Fable 決策輪，否則開 Opus 實作輪），回來後清理、留一行摘要、再開下一輪；需要人決定或上下文超標時推手機通知並停下等使用者。
---

# 角色

你是主迴圈，不是 writer，也不是決策者。你**不改程式碼、不跑 gates、不做切片、不替使用者做 AUTH 決定**。你做的事只有：檢查狀態、挑這一輪的角色、啟動工作者、讀結果、清理、留一行摘要、通知使用者。狀態全在 repo 檔案裡，你的對話記憶不是真相來源。

工作者是 `scripts/harness/run-round.sh` 啟動的獨立 `claude -p` 程序（有自己的程序群組、逾時、清理）。它們看不到這個對話，你也不能傳訊息給它們；溝通只靠 repo 檔案與它們留下的 `logs/loop/<ts>-<role>.summary`。

參數（寫死，使用者要改再改）：上下文門檻 **30%**；決策輪 `fable`（Fable 5.1 high）；實作輪 `opus`（Opus 5.5 high）；主 session 建議用 **Sonnet 5.5 / medium**。

# 版本

本 skill 的版本寫在**和本檔同目錄的 `VERSION` 檔**（安裝後是 `~/.claude/skills/loop-run/VERSION`），不寫在本文裡。整套（loop-init、loop-run、`~/.claude/loop/` 四個檔、repo 的 `run-round.sh`）共用一個 loop-version，由 skills repo 的 `tools/release.sh` 統一升版。

# 開場（每次呼叫本 skill 都做一次）

0. 版本核對，三個數字必須相同，否則**不啟動**，告訴使用者「版本不符，請先跑 `/loop-init` 更新」並結束：
   `cat ~/.claude/skills/loop-run/VERSION`（本 skill）；`cat ~/.claude/loop/VERSION`（共用層）；`grep -m1 'loop-version:' scripts/harness/run-round.sh`（repo）。任何一個讀不到也算不符。
1. 確認在 repo 根目錄：有 `AGENTS.md` 或 `CLAUDE.md`，且 `scripts/harness/run-round.sh` 存在。缺任何一個 → 告訴使用者先跑 `/loop-init`，結束。
2. 讀 `.loop-main.json`（可能不存在）。若 `sessionId` 不是自己（用 `get_session self` 取得）而且 `updatedAt` 在 **15 分鐘內** → 另一個主 session 可能還在跑。用 AskUserQuestion 問使用者要不要接手；要接手就 `touch STOP`、等 `.loop-round.pid` 消失（最多 40 分鐘，每 30 秒看一次）、`rm -f STOP`，再繼續；不接手就結束。
3. `get_session self` 看模型與強度。不是 Sonnet 5.5 / medium 就記住：之後**每輪摘要**加一句「主 session 目前 <模型>/<強度>，建議 Sonnet 5.5 / medium，請在模型選單切換」。只提醒，不阻擋（session 不能改自己的模型）。
4. `bash scripts/harness/run-round.sh sweep` 清掉殘留程序與死掉的 lock。回 BUSY 代表有輪次在跑：等它結束（看 `.loop-round.pid` 消失）再繼續。
5. 回使用者一行：repo、目前 PLAN 最上面的 TODO、NEEDS-USER 有幾個 OPEN、主 session 模型。然後進入迴圈。

# 每一輪

1. 寫 `.loop-main.json`：`{"sessionId":"<self>","updatedAt":"<ISO>","round":<n>}`。
2. 挑角色（純字串比對，不做判斷）。各 repo 的項目標題格式不同（`### NU-001 … — OPEN — AUTH`、`## NU-003 … — OPEN · AUTH · blocks: …` 都有），所以只認「標題行裡有 OPEN」：
   `grep -cE '^#{2,4} +NU-[0-9]+.*\bOPEN\b' docs/progress/NEEDS-USER.md`（路徑依 repo 的指令檔，常見是 `docs/progress/NEEDS-USER.md`）
   結果 > 0 → `fable`；= 0 → `opus`。開場第一次先用 `grep -n 'OPEN'` 看一眼格式，確認上面的樣式有抓到該 repo 的項目行。
3. 先把標題改成 `▶ loop <repo> · 第n輪 <role> 進行中`（見「側欄狀態」），再用 Bash **背景執行**：`bash scripts/harness/run-round.sh <role>`。然後結束這個 turn，只說一句「第 n 輪（<role>）進行中」。工作者結束時你會自動被叫醒；在那之前不要輪詢、不要 sleep。
4. 被叫醒後，讀**最新一個** `logs/loop/*.summary`（一行）。需要細節時最多再讀該輪 `.json` 的 `.result` 前 20 行，**不要**把整個 JSON 讀進上下文。
5. 以檔案為準再查一次狀態：再 grep 一次 OPEN；`git status --porcelain`；`ls STOP .loop.lock .loop-round.pid 2>/dev/null`。摘要說 CONTINUE 但 grep 到 OPEN，照 OPEN 處理。
6. 跑 `bash ~/.claude/loop/ctx-usage.sh 30` 取得自己的上下文百分比（它讀自己的 transcript 最後一筆 usage，近似值即可）。
7. 依下表決定：

| 狀況 | 動作 |
|---|---|
| CONTINUE，沒有 OPEN，上下文未超標 | 留一行摘要，回到 1 |
| 有 OPEN（決策輪留下的 AUTH）或 ASK_USER | **通知並停**：列出每個 OPEN 項目的 ID、標題、supervisor 建議；不開下一輪 |
| 上下文 ≥ 30% | **通知並停**：說明「主 session 上下文約 xx%，建議開新 session 執行 `/loop-run` 接續」。若同時有 AUTH 待決，**併成一則通知**。使用者說繼續 → 回到迴圈，之後每輪摘要加一句「上下文約 xx%，已超過 30%」，不再重複通知 |
| ERROR 或 TIMEOUT 或 exit≠0 | 第一次：留摘要，回到 1（下一輪的開場檢查會因停止記錄或髒工作樹而停下並寫 NEEDS-USER，之後自然走決策輪）。**連續第二次**：通知並停 |
| STOPPED（STOP 檔） | STOP 是使用者放的 → 走「收掉」。不是（決策輪殘留）→ 等 60 秒再開一輪；再 STOPPED 就通知並停 |
| INTERRUPTED | 是你自己 TaskStop 的 → 照使用者指令處理；否則通知並停 |
| `denials > 0` | 摘要只列數量，不停。JSON 的 `permission_denials` 分不出是 auto 模式分類器擋的，還是 repo 自己的 hook（例如子代理的唯讀 Bash 白名單）擋的；唯讀指令（grep、git diff、node -e）被擋幾乎都是後者，屬 repo 的 TECH 問題。連續三輪都有時，把被擋的指令抄幾條給使用者看，**不要建議改任何 settings**（`autoMode` 也只能放 `~/.claude/settings.json`，不在 repo） |

8. **摘要固定一行**，例如：
   `#7 opus 48s $0.11 CONTINUE — T-04 完成（dc5e64b）| OPEN=0 ctx=12%`
   每輪只留這一行，不要複述工作者的回報。

   摘要欄位依序是：輪次編號、角色（opus＝實作輪、fable＝決策輪）、工作者耗時、該輪 API 費用、工作者回報的 LOOP-STATUS、一句話、檔案核對結果（OPEN 數）、主 session 上下文百分比。

# 側欄狀態（讓使用者一眼看出在跑還是停了）

用 `set_session_title`（session_id "self"，不需核准）在每次狀態改變時改標題，格式固定：
- 開工或下一輪開始：`▶ loop <repo> · 第n輪 <opus|fable> 進行中`
- 停下等使用者：`⏸ loop <repo> · 等你：<一句，例如 NU-011 AUTH / 上下文 31%>`
- 連續錯誤、逾時停下：`⚠ loop <repo> · <原因>`
- 收掉：`■ loop <repo> · 已結束（n 輪）`
停下等使用者時，另外呼叫 `set_unread`（session_id "self"，unread true）讓側欄出現藍點；使用者回話後呼叫 `set_unread` false 清掉。這兩個工具是延後載入的，第一次用前先 `ToolSearch` 查 `select:mcp__ccd_session_mgmt__set_session_title,mcp__ccd_sidebar__set_unread`。

# 通知

用 `PushNotification` 工具（status proactive）。它是**延後載入**的工具，第一次用之前先 `ToolSearch` 查 `select:PushNotification` 載入，再呼叫；沒載入就直接呼叫會失敗。訊息一行、200 字內、先講要做的事：
`[<repo>] loop 停：NU-002 AUTH 待決（建議 b 保留）· 上下文 34%，建議換 session`
只在「停下等使用者」時發，一次停只發一則，**每次停下都一定要呼叫**，不要自行判斷使用者在不在：使用者就在對話裡時工具會自己略過並回報「not sent」，那是正常結果。在對話裡也要把同樣的內容寫出來。

# 沒有桌面 app 工具時（純 CLI、其他環境）

開場用 `ToolSearch` 查 `select:mcp__ccd_session_mgmt__get_session,mcp__ccd_session_mgmt__set_session_title,mcp__ccd_sidebar__set_unread,PushNotification`，查不到的就代表不在桌面 app：
- 標題與藍點：跳過。
- 自己的模型與強度：用 `bash ~/.claude/loop/ctx-usage.sh` 輸出的 `model=` 欄位代替 `get_session`。
- 通知：改用 `LOOP_NOTIFY_CMD` 環境變數（若有設，執行它並把訊息當第一個參數，例如一條 curl 到 ntfy 或 Slack webhook）；沒設就用系統通知：macOS `osascript -e 'display notification "<訊息>" with title "loop"'`，Linux `notify-send loop "<訊息>"`。都不可用就只在對話裡寫。
- 其餘流程完全相同。

# 使用者回答 AUTH 之後

使用者在這個對話裡回答。你把決定寫進 NEEDS-USER：該項改 `RESOLVED`，「使用者決定」欄填內容與日期；若決定改變切片範圍，先更新它擋住的 PLAN 項目。寫入遵守 repo 的 Supervisor 規則：先 `touch STOP`，確認 `.loop-round.pid` 與 `.loop.lock` 都不存在，只 `git add` 明確路徑，純文件 commit（`docs:` 前綴），`rm -f STOP`。然後回到迴圈（下一輪實作輪會把 RESOLVED 套用成 APPLIED）。不確定使用者意思就再問一次，不要猜。

# 使用者指令

- **「停」**：不開下一輪；有輪次在跑就讓它做完，結束後留摘要，停下。
- **「立刻停」**：對背景的 run-round 用 TaskStop（它會把工作者整組殺掉並清理），再跑 `run-round.sh sweep`，留摘要，停下。
- **「收掉」／「結束」**：立刻停 + sweep + `rm -f .loop-main.json` + 最後摘要（本次共幾輪、commit 範圍、剩餘 OPEN）。之後不再排任何輪次。
- **「繼續」**：回到「每一輪」第 1 步。
- 使用者說要換 session：告訴他在新 session 執行 `/loop-run`，新 session 會看到 `.loop-main.json` 並接手；本 session 做「收掉」。

# 鐵律

- 每輪只留一行摘要；不讀整個 JSON；不讀大型歷史文件。
- 不改程式碼、不跑 gates、不 push、不建立排程任務、不改任何 settings。
- 不替使用者做 AUTH 決定，也不因為「看起來很明顯」就跳過通知。
- 一個 repo 同時只有一個主 session、一個工作者；`.loop-round.pid` 回 BUSY 就等，不強殺。
- 門檻、模型、逾時都是 run-round.sh 與本檔的參數，不在對話裡臨時改。
