# AGENTS.md — relay-test（迷你 loop harness，只用來測試 loop 機制）

這個 repo 沒有真正的產品。每個 PLAN 項目都是「在 `work/` 建一個小檔案並跑假 gate」。規則刻意與正式 repo 的 loop 協定同構。

## 1. Loop 協定（每輪）

開場：
1. `bash scripts/harness/loop-start.sh`。結束碼 4：**立即結束，不寫任何檔、不 commit**。結束碼 3：依第 3 節寫停止記錄後結束。結束碼 0：它已建立 `.loop.lock`，照它印出的 PLAN 項目做。
2. 讀 `docs/progress/STATUS.md`、`PLAN.md`、`NEEDS-USER.md`。有 RESOLVED 的 NEEDS-USER 項目先套用（依其「套用方式」改 PLAN），把它改成 APPLIED，再開始切片。

中間：只做 PLAN 最上面一個 **TODO**，不順手做別的。每個長步驟前 `touch .loop.lock`。中途發現 `STOP` 檔：只回報，不改檔、不 commit，移除 lock 後結束。

結尾：
1. 跑該項目寫的 gate 指令。gate 失敗：寫 NEEDS-USER（TECH，附輸出）並依第 3 節停止。
2. `git add` 明確路徑（不用 `-A`），commit，訊息 `feat(<ID>): …` 或 `docs: …`。
3. 寫 `docs/progress/log/<ID>.md`（做了什麼、gate 輸出、commit hash）。更新 STATUS（最後 commit、最後輪次時間）、PLAN（本項 DONE）。
4. `rm -f .loop.lock`，結束。
5. **回覆的最後一行固定是** `LOOP-STATUS: CONTINUE|ASK_USER|STOPPED|ERROR — <一句摘要>`。CONTINUE＝切片完成；ASK_USER＝有 AUTH 項目等使用者；STOPPED＝因 STOP 檔或 lock 未開工；ERROR＝gate 失敗或其他停止條件。

## 2. 單一 writer

同一時間只有一個代理寫 working tree。子代理只做調查。不 push（本 repo 沒有 remote）。不開 dev server；gate 結束後不得留下任何背景程序。

## 3. 停止條件與停止記錄

遇到 AUTH 待決、gate 失敗、PLAN 無 TODO：在 NEEDS-USER 開（或更新）一項，STATUS 記一行，**只提交這兩個檔**。未完成修改留在工作樹，`git status --porcelain` 原樣寫進該項。`rm -f .loop.lock`，結束，最後一行 `LOOP-STATUS: ASK_USER` 或 `ERROR`。

## 4. NEEDS-USER 協定

每項：`### NU-xxx 標題 — OPEN|RESOLVED|APPLIED — TECH|AUTH`，內含背景、選項、建議、擋住的 PLAN 項目、使用者決定、套用方式。
- TECH：決策輪（supervisor）可自行決定：填「決定」、標 `decided-by: supervisor`、改 RESOLVED。
- AUTH（刪已追蹤檔、改 PLAN 順序、改驗收範圍、任何遠端操作）：只有使用者能決定，決策輪只能留 OPEN 並寫一句建議。

## 5. Supervisor（決策輪）規則

不改程式碼與 `work/`，只做純文件 commit（`docs:` 前綴）。寫入前 `touch STOP`，確認 `.loop.lock` 不存在，寫完 commit 後 `rm STOP`。
