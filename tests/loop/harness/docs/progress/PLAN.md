# PLAN

格式：`### ID 標題 — TODO|DONE|BLOCKED`。只做最上面一個 TODO。

### T-01 建立 work/T-01.txt — TODO
- 目標：建立 `work/T-01.txt`，內容一行 `T-01 done <ISO 時間>`。
- gate：`bash scripts/harness/gate.sh T-01`

### T-02 建立 work/T-02.txt（gate 會留下背景程序） — TODO
- 目標：建立 `work/T-02.txt`，內容一行 `T-02 done <ISO 時間>`。
- gate：`bash scripts/harness/gate.sh T-02 --leave-process`（這個 gate 故意留下一個 sleep 程序，照跑即可，不要自己去殺它，這是在測 run-round 的清理）

### T-03 建立 work/T-03.txt（gate 會卡住） — TODO
- 目標：建立 `work/T-03.txt`，內容一行 `T-03 done <ISO 時間>`。
- gate：`bash scripts/harness/gate.sh T-03 --hang`（這個 gate 故意卡 10 分鐘，照跑並等它，不要中斷，這是在測 run-round 的逾時）

### T-04 建立 work/T-04.txt — TODO
- 目標：建立 `work/T-04.txt`，內容一行 `T-04 done <ISO 時間>`。
- gate：`bash scripts/harness/gate.sh T-04`
