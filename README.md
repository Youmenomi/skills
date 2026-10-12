# skills

Agent Skills（`SKILL.md` 格式）的集合。目前以 Claude Code 為主，結構與 [Agent Skills](https://agentskills.io) 開放規格相容，之後可逐個 skill 標記支援其他工具。

## 安裝

用 [skills CLI](https://github.com/vercel-labs/skills)，會列出 skill 讓你勾選、並選擇裝到哪些 agent：

```bash
npx skills add Youmenomi/skills -g
```

沒有 Node 的環境，或只想裝到 Claude Code：

```bash
git clone https://github.com/Youmenomi/skills.git && cd skills && ./install.sh
```

兩種方式都會把 `skills/<name>/` 複製到 `~/.claude/skills/<name>/`。更新就是再跑一次。

## 目前的 skill

### autoloop — 自動開發 loop

一個 skill 兩個子指令：

| 子指令 | 做什麼 |
|---|---|
| `/autoloop init` | 把 repo 準備好：新 repo 從零建 harness（指令檔、PLAN/STATUS/NEEDS-USER、驗收清單、子代理、settings）；已有 harness 的瘦身指令檔。再寫允許規則、ignore 與版本標記 `.claude/autoloop.json`。每個 repo 做一次，skill 升版後再做一次 |
| `/autoloop run` | 本 session 當主迴圈：每輪直接呼叫 skill 的 `run-round.sh` 開一個獨立的 `claude -p` 工作者（NEEDS-USER 有 OPEN 就開 Fable 決策輪，否則開 Opus 實作輪），清理、留一行摘要、再開下一輪；要人決定或上下文超標時推手機通知並停下 |

所有執行檔（輪次啟動器、兩個 prompt、上下文計算、版本）都在 `skills/autoloop/assets/`，repo 裡不放任何腳本。skill 可以裝在使用者層（`~/.claude/skills/`，`npx skills add -g`）或 repo 層（`<repo>/.claude/skills/`，不加 `-g`），`init` 會把找到的那個路徑寫進 `.claude/autoloop.json` 和允許規則。`/autoloop run` 開場要求 `.claude/autoloop.json` 的版號和 skill 的 `VERSION` 完全相同，不符就只提示重跑 `/autoloop init`，不自動改。

前提與限制：
- macOS 或 Linux（原生 Windows 不支援，請用 WSL）；需要 `jq`、`lsof`、`perl`。
- 工作者是獨立的 Claude Code CLI 程序，要另外安裝並登入：`curl -fsSL https://claude.ai/install.sh | bash`，然後執行 `claude` 登入。
- 預設模型 Fable 5.1（決策）與 Opus 5.5（實作），沒有存取權時在 repo 的 `.claude/settings.json` `env` 用 `LOOP_MODEL_DECIDE`／`LOOP_MODEL_IMPLEMENT` 換；逾時、預算、殘留程序名單、上下文視窗、通知指令也都是 `LOOP_*` 環境變數，見 SKILL.md。
- 桌面 app 以外的環境少了標題、側欄藍點與手機推播，其餘相同（SKILL.md 內有降級規則）。

## 結構

```
skills/<name>/SKILL.md      每個 skill 一個資料夾，assets/ 跟著 skill 走
tests/<skill>/              測試床與情境清單（autoloop 的是一個迷你 harness）
changes/                    待發布的 change 檔（type: patch|minor|major）
tools/check.sh              frontmatter、版本、change 檔檢查（CI 也跑它）
tools/release.sh            升版、CHANGELOG、tag、fast-forward main
install.sh                  複製到 ~/.claude/skills/
```

## 改動與升版

- 日常改動在 `dev` 分支。改了 `skills/` 任何檔，就在 `changes/` 放一個 `<slug>.md`，檔頭 `type: patch|minor|major`，接一行說明（`tools/check.sh` 會要求）。只改文件、tests、tools 不需要。
- 版本是 semver，單一來源 `skills/autoloop/assets/VERSION`：**patch** 修復、**minor** 功能、**major** 不相容。
- 發布：在 `dev` 跑 `tools/release.sh`，它取最高的 type 升版、合併 `changes/` 進 CHANGELOG、commit、打 tag `autoloop-vX.Y.Z`、fast-forward `main`；然後 `git push origin dev main --follow-tags`。發布前依 `tests/loop/CASES.md` 跑一遍測試床。**main 永遠是已發布狀態**，CI 會擋 main 上殘留的 change 檔。
- 使用者更新：重新安裝，然後在每個 repo 重跑 `/autoloop init`（任何版本都要，`.claude/autoloop.json` 的版號必須完全相同）。
- CI（GitHub Actions）每次 push 跑 `tools/check.sh`。
