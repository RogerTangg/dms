# 商業邏輯與工作流（Business Logic & Workflow）

> 通用工作流樣板，萃取自一個出勤簽到應用。`{AppPrefix}`、欄位名為佔位符。
> 對應可重用程式碼見 `examples/` 與 `references/formula-cookbook.md`、
> `references/lotusscript-cookbook.md`。

## 一、批次戳記（選取 → StampAll）

**場景**：使用者在視圖多選文件，套用同一欄位值（批次分組、批次設定狀態、批次歸檔）。

```
使用者在視圖選取 N 筆文件
        │
        ▼
從 Actions 選單執行 Agent A{AppPrefix}NN（手動、$AssistTrigger=4）
        │
        ▼
db.UnprocessedDocuments → 取得選取集合 dc
        │
   dc.Count = 0 ? ──是──▶ Exit Sub
        │否
        ▼
InputBox/對話框 取得欲寫入的值
        │
   值 = "" ? ──是──▶ Exit Sub
        │否
        ▼
dc.StampAll("欄位名", 值)   ← 一次寫入所有選取文件，免逐筆 Save
```

關鍵 API：`NotesDatabase.UnprocessedDocuments`（手動代理中即為選取集）、
`NotesDocumentCollection.StampAll(field, value)`（高效批次寫入單一欄位）。
完整骨架見 `examples/agent-template.ls`。

## 二、開單帶值（@DbLookup 自動填入）

**場景**：建立交易/申請文件時，輸入主鍵後自動帶出主檔資料，避免重打與不一致。

```
使用者於子文件輸入 keyField
        │
        ▼
Computed 欄位執行 @DbLookup(""\:"NoCache"; ""; "V{AppPrefix}03"; keyField; "欄位名")
        │
        ▼
經 lookup view（依 keyField 排序）找到主檔
        │
        ▼
回傳 displayName / 其他欄位 填入子文件
```

設計重點：一律帶 `"NoCache"`（主檔可能更新）；lookup view 與 key 固定；
找不到時 @DbLookup 回 `@Error`，以 `@If(@IsError(...); ""; ...)` 防呆並加 Input Validation。

## 三、簽核狀態機（Approval State Machine）

**設計意圖**（以狀態欄位驅動）：

```
申請人填寫申請表 → processStatus = "待審核"（建立時 Computed when Composed 設初值）
        │
        ▼
審核人於「未審核」視圖（SELECT form="F{AppPrefix}05" & processStatus="待審核"）檢視
        │
        ▼
按「核准 / 駁回」Action：
   processStatus := "核准" / "駁回"
   approveNotesID := @Name([CN]; @UserName)
   approveDate    := @Now
   （可選）@MailSend 通知申請人
```

**閉環檢查清單**（避免「只有欄位、沒有流程」的反模式）：
- [ ] 有 Action/Agent 真正推進 `processStatus`（非手動改欄位）。
- [ ] 狀態變更同時寫入審核人與 `@Now` 時間戳，留稽核軌跡。
- [ ] 「未審核」視圖選擇公式正確過濾狀態（常見缺陷見 known-issues.md）。
- [ ] 狀態字串大小寫/全半形一致（與表單寫入值比對）。
- [ ] （可選）通知機制：`@MailSend` 或 `NotesDocument.Send`。

完整實作走讀見 `examples/workflow-pattern.md`。

## 四、導覽流程（Navigation）

```
開啟資料庫 → Frameset
   ├─ (左) 導覽 Outline ──連結──▶ 主要視圖
   └─ (右) 預設視圖 ──雙擊──▶ 以對應 Form 開啟文件
```

注意：未掛入 Outline 的視圖（如某些流程視圖）需另行開啟；新增重要視圖時記得同步加入
導覽 Outline，否則使用者找不到。

## 五、@DbColumn 取唯一值清單

下拉選單/關鍵字欄位可由視圖某欄動態取值，避免硬編碼選項：

```formula
@DbColumn(""\:"NoCache"; ""; "V{AppPrefix}02"; 欄位位置)
```

用於「分組名稱」「假別」等需與既有資料一致的選單。詳見 formula-cookbook.md。
