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

兩種方式都會把 `skills/<name>/` 複製到 `~/.claude/skills/<name>/`。

## 目前的 skill

| skill | 用途 | 需要 |
|---|---|---|
| `loop-init` | 把一個 repo 準備成能自動開發的狀態：建 harness（指令檔、PLAN/STATUS/NEEDS-USER、驗收清單、子代理、settings）、裝執行器 `run-round.sh`。每個 repo 跑一次 | Claude Code 桌面 app 或 CLI；獨立 CLI 已登入 |
| `loop-run` | 主 session 當迴圈：每輪開一個獨立的 `claude -p` 工作者（有待決項目開 Fable 決策輪，否則開 Opus 實作輪），清理、留一行摘要、再開下一輪；要人決定或上下文超標時通知並停 | 先在該 repo 跑過 `/loop-init` |

兩個 loop skill 共用一個 `loop-version`（見 `skills/loop-init/assets/VERSION`），`loop-run` 開場會核對版本，不符就要求重跑 `/loop-init`。

## 前提與限制（loop）

- macOS 或 Linux（原生 Windows 不支援，請用 WSL）；需要 `jq`、`lsof`、`perl`。
- 工作者是獨立的 Claude Code CLI 程序，要另外安裝並登入：`curl -fsSL https://claude.ai/install.sh | bash`，然後執行 `claude` 登入。
- 預設模型 Fable 5.1（決策）與 Opus 5.5（實作），沒有存取權時在 repo 的 `.claude/settings.json` `env` 用 `LOOP_MODEL_DECIDE`／`LOOP_MODEL_IMPLEMENT` 換。
- 桌面 app 以外的環境少了標題、側欄藍點與手機推播，其餘相同（`loop-run` 內有降級規則）。

## 結構

```
skills/<name>/SKILL.md      每個 skill 一個資料夾，assets/ 跟著 skill 走
tests/<skill>/              測試床與情境清單（loop 的是一個迷你 harness）
tools/check.sh              frontmatter 與版本一致性檢查
install.sh                  複製到 ~/.claude/skills/
```

## 改動與升版

- 改了 `skills/loop-init/` 或 `skills/loop-run/` 任何檔：在 `changes/` 放一個一行的 `<slug>.md` 說明改了什麼（`tools/check.sh` 會要求）。
- 發布：`tools/release.sh` 把 `changes/` 合併進 CHANGELOG、版本 +1（單一來源 `skills/loop-init/assets/VERSION`，同步到 `skills/loop-run/VERSION`）、commit、打 tag `loop-v<N>`；然後 `git push --follow-tags`。發布前依 `tests/loop/CASES.md` 跑一遍測試床。
- `run-round.sh` 原版第二行是 `# loop-version: @VERSION@`，`/loop-init` 安裝時填入數字；`/loop-run` 開場核對 skill、`~/.claude/loop/`、repo 三處版本，不符就要求重跑 `/loop-init`。
- CI（GitHub Actions）每次 push 跑 `tools/check.sh`。
