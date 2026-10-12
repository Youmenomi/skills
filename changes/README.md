# changes/

改了 `skills/` 任何東西，就在這裡放一個 `<slug>.md`：檔頭宣告類型，接著一行說明（進 CHANGELOG）。

```markdown
---
type: patch
---
run-round.sh 的 SWEEP_PATTERN 加入 cargo 與 rustc
```

| type | 意思 | 發布後使用者要做的 |
|---|---|---|
| `patch` | 修復，行為更正 | 重新安裝 |
| `minor` | 新功能，向後相容 | 重新安裝 |
| `major` | 不相容：stub 範本變了（repo 裡有副本）、或流程對既有 repo 不相容 | 重新安裝 + 每個 repo 重跑 `/autoloop init` |

規則：日常改動在 `dev` 分支；`tools/check.sh` 看到 skills 有改動但這裡沒有檔就 FAIL；main 上這裡必須是空的。發布跑 `tools/release.sh`（取最高的 type 升版、合併進 CHANGELOG、刪掉這些檔、commit、tag、fast-forward main），然後 `git push origin dev main --follow-tags`。
