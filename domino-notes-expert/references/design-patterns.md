# 設計模式（Design Patterns）

> 本專案族群慣用的可重用結構。`{AppPrefix}` 為佔位符。

## P1. 主檔 + Lookup View + @DbLookup 鬆耦合

**問題**：多個文件型別需共用主檔資料（人員、品項…），且主檔會更新。

**作法**：
1. 主檔（`F{AppPrefix}01`）放邏輯主鍵 `keyField`。
2. 建隱藏 lookup view（`V{AppPrefix}03`）：第一欄 = `keyField`（升冪排序），
   後續欄 = 要被帶出的欄位；選擇公式 `SELECT form = "F{AppPrefix}01"`；`$Flags` 設隱藏。
3. 子文件以 Computed 欄位 `@DbLookup(""\:"NoCache"; ""; "V{AppPrefix}03"; keyField; "欄位")` 帶值。

**為何如此**：文件互相獨立、無實體父子鏈、重建索引安全、語意近似關聯式 join；
比 Response 階層更易維護與遷移。**重用**既有 lookup view，勿建平行 lookup。
範例見 `examples/view-template.dxl`。

## P2. 選取文件批次戳記（Batch Stamp）

**問題**：對視圖選取的多筆文件套用同一欄位值。

**作法**：手動受限代理（`$AssistTrigger=4`、`$Restricted=1`）→ `db.UnprocessedDocuments`
取選取集 → `dc.StampAll(field, value)`。**為何如此**：`StampAll` 一次寫入、不需逐筆
`doc.Save`，遠比迴圈高效。骨架見 `examples/agent-template.ls`。

## P3. Frameset + Outline 導覽

**問題**：提供穩定的 Notes Client 導覽。

**作法**：Frameset 左欄載入導覽 Outline、右欄載入預設視圖；Outline 條目連結各主要視圖。
**為何如此**：集中導覽、單一改點；新增視圖只需加 Outline 條目。

## P4. 狀態欄位驅動的簡易工作流

**問題**：申請/簽核流程。

**作法**：以 `processStatus` 文字欄位為狀態機核心，搭配「未審核」過濾視圖
（`SELECT form="F{AppPrefix}05" & processStatus="待審核"`）與核准/駁回 Action
（設狀態、寫 `approveNotesID`/`@Now`、可選通知）。**為何如此**：輕量、無需 XPages，
但**務必閉環**（見 business-logic.md 第三節）。

## P5. Computed-when-Composed 快照

**問題**：某些值需凍結在建立/核准當下（單號、申請人、核准金額）。

**作法**：用 `Computed when Composed` 或在 Action 中一次寫入，而非 `Computed`
（後者會隨主檔變動）。**為何如此**：保存歷史真值，不被後續主檔變更污染。

## P6. 分類視圖（Categorized View）做分組檢視

**問題**：依某維度（分組、日期、地點）聚合檢視。

**作法**：將分類欄設為 Categorized（DXL `$Collation` 標示）；第一分類欄即聚合鍵。
**為何如此**：免寫程式即得樹狀聚合；分組鍵由 `@DbColumn` 動態供應可保一致。

---

## 反模式（Anti-Patterns，務必避免）

| 反模式 | 後果 | 正解 |
|---|---|---|
| 視圖選擇公式與用途不符（複製貼上殘留） | 列出錯誤文件型別 | 校對 `SELECT form="正確代號"` + 狀態過濾 |
| `_1` 自動後綴欄位被沿用 | 引用到死欄位、語意混亂 | 解決命名衝突，新欄位用清楚英文名 |
| 帶值用 `Computed` 卻需快照 | 歷史值被改動 | 改 `Computed when Composed` |
| @DbLookup 未加 `NoCache` | 帶到舊主檔值 | 一律 `""\:"NoCache"` |
| 重複公式散落各表單 | 難維護 | 抽 Subform / Shared Action / Script Library |
| 狀態欄位無推進機制 | 流程不閉環、無稽核 | 加 Action 設狀態 + `@Now` + 通知 |
| 硬編碼伺服器/路徑/人名 | 換環境即壞 | 參數化（profile 文件、環境變數、設定檔） |

詳細嚴重度分級見 `references/known-issues.md`（隨附於本 skill 的審核產出）。
