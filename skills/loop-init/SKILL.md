---
name: loop-init
description: 把一個 repo 準備成能用 /loop-run 自動開發的狀態：新 repo 從零建立「一切片一全新上下文」的 harness（指令檔、PLAN/STATUS/NEEDS-USER、驗收清單、CODEMAP、ADR、子代理、settings），已有 harness 的 repo 則瘦身指令檔並裝上執行器（run-round.sh、允許規則、ignore）。取代舊的 loop-harness-init；每個 repo 做一次，之後改了共用檔再跑一次即可。
---

# 版本

本 skill 是 **loop-version 1**，與 `assets/VERSION`、`loop-run`、`~/.claude/loop/VERSION`、repo 裡 `run-round.sh` 的 `# loop-version:` 行一致。升版規則：改了 assets 任何一檔或兩個 skill 的流程，就把這五處一起加 1；`loop-run` 看到任一處不符就不會啟動，所以更新 skill 後**一定要在每個 repo 重跑 `/loop-init`**，它負責把 `~/.claude/loop/` 和 repo 一起更新到同一版。

# 原則

狀態在 repo 不在對話；一輪一個切片，做完就結束；驗收狀態只有一個來源；需要人決定的事寫進檔案等人，不硬做。**決策政策（TECH／AUTH 分類、例外、supervisor 寫入流程）只存在 `~/.claude/loop/decide.md`，指令檔不抄全文**，只放 repo 專屬的補充。工作者 prompt 在 `~/.claude/loop/implement.md`，執行器在 `~/.claude/loop/run-round.sh`，這三個是所有 repo 共用的。

# 開始前

1. `git status --porcelain` 必須乾淨；不乾淨先問使用者，不 reset、stash、覆寫。
2. 共用層 `~/.claude/loop/`（執行期讀的穩定路徑）由本 skill 維護：原版在本 skill 資料夾的 `assets/`（`run-round.sh`、`decide.md`、`implement.md`、`ctx-usage.sh`）。`~/.claude/loop/` 不存在就從 `assets/` 建立；已存在但和 `assets/` 不同就顯示 diff 問使用者要用哪一邊（使用者可能直接改了 `~/.claude/loop/` 的檔）。永遠不要自己重寫這四個檔的內容。
3. 環境檢查：`uname` 是 Darwin 或 Linux（原生 Windows 不支援，請用 WSL）；`jq`、`lsof`、`perl` 都在 PATH（缺的給安裝指令，macOS 用 brew、Debian 系用 apt）。獨立 CLI 已安裝（預設 `~/.local/bin/claude`，可用 `CLAUDE_BIN` 指定；沒有就給 `curl -fsSL https://claude.ai/install.sh | bash`）且已登入：`claude auth status` 的 `loggedIn` 為 true。否則請使用者在終端機執行 `claude` 登入；憑證由使用者親自處理。
   可調參數都放 repo 的 `.claude/settings.json` 的 `env`，不碰全域設定：`LOOP_MODEL_DECIDE`／`LOOP_MODEL_IMPLEMENT`（預設 claude-fable-5-1／claude-opus-5-5）、`LOOP_EFFORT_DECIDE`／`LOOP_EFFORT_IMPLEMENT`（預設 high）、`LOOP_TIMEOUT`、`LOOP_BUDGET`、`LOOP_SWEEP_PATTERN`、`LOOP_CTX_WINDOW`（主 session 視窗 token 數，預設 Claude 5 系列 1M）、`LOOP_NOTIFY_CMD`（非桌面 app 環境的通知指令）。使用者沒有 Fable 或 Opus 的存取權時，請他在這裡換模型。
4. 判斷模式：
   - **新 repo**：沒有指令檔的 loop 協定、沒有 `docs/progress/PLAN.md` → 走「建立 harness」再「裝執行器」。
   - **已有 harness**：有協定與進度檔 → 走「瘦身指令檔」再「裝執行器」。
   - **已 init 過**：`scripts/harness/run-round.sh` 已存在 → 比對它的 `loop-version` 與 `~/.claude/loop/VERSION` 是否等於本 skill 版本；舊的就更新（顯示 diff 讓使用者看一眼，內容是 assets 原版就直接覆蓋，使用者自己改過的才問）；指令檔有舊段落就瘦身。
5. 新 repo 時先盤點：建置／測試／lint 指令、既有指令檔（CLAUDE.md 或 AGENTS.md，兩者只能留一個，有 CLAUDE.md 時 AGENTS.md 不會被讀）、測試工具、既有進度文件與大小、gates 會不會啟動長駐子程序。然後一次問使用者三件事：指令檔用哪個檔名；哪些檢查每切片必跑、哪些 milestone 才跑、哪些定期跑；允不允許 push，以及這個 repo **額外**要問人的動作（decide.md 已涵蓋刪已追蹤檔、遠端操作、放寬 gate、改驗收或方向、改 PLAN 順序、改寫 history、付費、核准 ADR）。

# 建立 harness（新 repo）

指令檔 200 行內，用一般 Markdown 連結指向其他文件，不用 @ 匯入。章節固定：

1. **邊界與工程規範**：從既有文件濃縮，不複製整份規格。
2. **Gates 分級**：每切片／milestone／定期三級，各列實際指令。不得為綠燈刪測試、放寬 tolerance、重跑到綠。pre-commit 只檢查變動檔；完整掃描留在完整 CI。
3. **Loop 協定**：開場先跑開場腳本（`npm run loop:start` 或等價，結束碼 0＝有工作且已建 lock、3＝停止條件、4＝STOP 檔或另一輪進行中），讀 STATUS、PLAN、NEEDS-USER，必要時讀 CODEMAP；有 RESOLVED 的 NEEDS-USER 項目先套用再開工。中間只做 PLAN 最上面一個 TODO；每個長步驟前 `touch .loop.lock`；中途發現 STOP 只回報不改檔。結尾跑適用 gates、請 reviewer 子代理看實際 diff、commit、寫切片記錄 `docs/progress/log/<切片ID>.md`、更新 STATUS 與驗收狀態、RESOLVED 改 APPLIED、`rm -f .loop.lock`。
4. **定期完整檢查**：距上次完整 CI 超過 24 小時或已完成 5 個實作切片時，該輪只跑完整 CI；失敗寫 NEEDS-USER 並停止。
5. **停止條件與停止記錄**：STOP 檔；同一切片連續兩輪 gates 不過；需要人決定；工作樹的未提交檔與停止項清單不一致；STATUS 起點核對不符；PLAN 無 TODO。停止時只提交 NEEDS-USER 與 STATUS 的停止記錄，`git status --porcelain` 原樣寫進該項。例外（可帶著 BLOCKED 提交）的三個條件同時成立才適用，且不得把驗收項改 PASS。
6. **單一 writer**：同一時間只有一個代理寫 working tree；子代理只做調查與審查；supervisor（決策輪）寫入前建 STOP、寫完移除。
7. **PLAN 規則**：順序由使用者決定；代理可拆分項目、標 DONE、把新項目插在最後一項之前；每項含 ID、目標、驗收條件與驗證指令、狀態；200 行內。
8. **NEEDS-USER 格式與本 repo 的補充**：每項 `### ID 標題 — OPEN|RESOLVED|APPLIED — TECH|AUTH`，含背景、選項、建議、擋住的 PLAN 項目、使用者決定、套用方式。寫一句：「決策政策（哪些可由 supervisor 決定、例外、寫入流程）見 loop 共用的 `decide.md`；本 repo 額外必須問使用者的動作：…」。writer 在輪中遇到 TECH 問題可交 `decider` 子代理，ESCALATE 才寫 NEEDS-USER。
9. **ADR 規則**：架構決定以 PROPOSED 提交並寫 NEEDS-USER，核准前不做依賴它的切片。
10. **腳本規則**：`scripts/harness/*.sh` 一律 `set -eu`，**`run-round.sh` 除外**（它負責清理，不得遇錯即停）；有逾時的 gate 逾時要終止整個程序群組並清暫存；每輪結尾不得留下背景程序。
11. **Git 規則**：小而完整的 commit，Conventional Commits；不 push、不開 PR、不改全域設定。
12. **環境備註**：機器、工具版本、已知的環境坑。
13. **執行方式**：「用 `/loop-run` 驅動，每輪由 `scripts/harness/run-round.sh` 啟動獨立工作者；逾時與費用上限可在 `.claude/settings.json` 的 `env` 設 `LOOP_TIMEOUT`、`LOOP_BUDGET`；log 在 `logs/loop/`。」

其他檔案：`docs/progress/PLAN.md`、`STATUS.md`（含 `last-round-commit:` 行）、`NEEDS-USER.md`、`log/`；機器可讀的驗收清單（`docs/progress/ACCEPTANCE.json`，每項有通過條件、負向案例、狀態 PASS／FAIL／BLOCKED／NOT_RUN／NA、證據路徑）；`docs/CODEMAP.md`（200 行內）；`docs/adr/` 與模板；`.claude/agents/`：explorer（sonnet、medium、唯讀）、doc-writer（sonnet、medium，只寫 docs）、reviewer（opus、xhigh、唯讀，看實際 diff）、decider（fable、high、唯讀，輪中 TECH 決策）；唯讀子代理用白名單腳本把 Bash 限制成唯讀。既有巨大的進度文件原文搬到 `docs/progress/archive/`。PLAN 第一項放「驗收稽核」；gates 會啟動長駐子程序時，第一個產品切片之前加「逾時終止與殘留清理」項目。

# 瘦身指令檔（已有 harness）

指令檔是使用者的規則，**先列出要改的段落與替換文字，使用者同意才動**，一次 `docs:` commit：
- NEEDS-USER 協定裡的 TECH／AUTH 分類細則、decider 核准流程、Supervisor 規則整節 → 換成第 8 章節那一句指向 `decide.md` 的話，加上本 repo 額外要問人的動作（從原文裡挑出 decide.md 沒有的）。
- 排程相關章節 → 換成第 13 章節「執行方式」。
- 腳本規則補 `run-round.sh` 例外；Supervisor／結尾補「不得留下背景程序」（若缺）。
- 其餘章節不動。改完跑 repo 的文件檢查（若有）。

# 裝執行器

1. `mkdir -p scripts/harness && cp ~/.claude/loop/run-round.sh scripts/harness/run-round.sh && chmod +x`。路徑固定是 `scripts/harness/run-round.sh`，不管 repo 其他腳本放哪（`run-round.sh` 以自己的位置推算 repo 根目錄，`/loop-run` 也只認這個路徑）；已存在且不同就顯示 diff 問要不要覆蓋。
2. `.gitignore` 確保有 `STOP`、`.loop.lock`、`.loop-round.pid`、`.loop-main.json`、`logs/`（沿用檔內既有的寫法，例如前導 `/`）。
3. `.claude/settings.json`：`permissions.allow` 加 `"Bash(scripts/harness/run-round.sh *)"`；新 repo 另加 `"effortLevel": "high"`、deny `git push`、只預先允許明確列出的安全指令。已有內容就合併，不動其他鍵。
4. 看 gates 用到的長駐程序是否在 `run-round.sh` 的 `SWEEP_PATTERN`（vite、node、npm、blender、cargo、playwright、chrom*、python、tail…）裡；不在就建議在 `env` 設 `LOOP_SWEEP_PATTERN`。用最近幾個切片記錄的實際耗時估 `LOOP_TIMEOUT`（最長一輪的兩倍；預設 5400 秒）與 `LOOP_BUDGET`（預設 20 美元）。
5. 試跑 `bash scripts/harness/run-round.sh sweep`，應印出 `sweep: killed=[]`。
6. commit（`chore: loop runner` 或與 harness 一起），只 add 明確路徑。不 push。

# 收尾

回報：改了哪些檔、commit hash、指令檔行數、gates 分級、`SWEEP_PATTERN` 與逾時／預算、本 repo 額外的 AUTH 動作。下一步固定是：「開一個 Sonnet 5.5 / medium 的 session，執行 `/loop-run`」。若這個 repo 還有舊的 app 排程任務，提醒使用者停用或刪除。

# 不做的事

不建立排程任務、不 push、不改 `~/.claude/` 下的共用檔、不跑實作輪、不在未經使用者同意下改指令檔內容。
