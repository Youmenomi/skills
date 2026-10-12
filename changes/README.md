# changes/

改了 `skills/loop-init/` 或 `skills/loop-run/` 任何東西，就在這裡放一個 `<slug>.md`，內容一行，說改了什麼（給 CHANGELOG 用）。`tools/check.sh` 看到 skills 有改動但這裡沒有檔就會 FAIL。

發布時跑 `tools/release.sh`：它把這裡的檔合併進 CHANGELOG 的新段落、版本 +1、同步到 `skills/loop-run/VERSION`、刪掉這些檔、commit、打 tag。之後 `git push --follow-tags`，並在每個 repo 重跑 `/loop-init`。

例：`changes/sweep-pattern-cargo.md`
```
run-round.sh 的 SWEEP_PATTERN 加入 cargo 與 rustc
```
