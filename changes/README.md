# changes/

改了 `skills/` 任何東西，就在這裡放一個 `<slug>.md`：檔頭宣告類型，接著一行說明（進 CHANGELOG）。

```markdown
---
type: patch
---
run-round.sh 的 SWEEP_PATTERN 加入 cargo 與 rustc
```

| type | 意思 |
|---|---|
| `patch` | 修復，行為更正 |
| `minor` | 新功能，向後相容 |
| `major` | 不相容，既有 repo 的 harness 或流程要跟著改 |

不論哪一種，發布後使用者都要重新安裝並在每個 repo 重跑 `/autoloop init`（stub 版號必須和 skill 完全相同）。

規則：日常改動在 `dev` 分支；`tools/check.sh` 看到 skills 有改動但這裡沒有檔就 FAIL；main 上這裡必須是空的。發布跑 `tools/release.sh`（取最高的 type 升版、合併進 CHANGELOG、刪掉這些檔、commit、tag、fast-forward main），然後 `git push origin dev main --follow-tags`。
