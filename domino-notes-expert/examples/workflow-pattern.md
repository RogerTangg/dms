# 工作流實作範例：申請 → 簽核狀態機

完整、可直接調整的簽核流程範例。萃取自一個請假申請流程並通用化。
為何這樣設計：以單一狀態欄位 `processStatus` 驅動，輕量、無需 XPages，
但**務必閉環**（狀態要有 Action 推進、要留稽核軌跡）。對照 references/business-logic.md 第三節。

## 角色與資料

- Form：`F{AppPrefix}05 申請單`，關鍵欄位：
  - `keyField`（申請人識別，外鍵）
  - `displayName`（@DbLookup 帶入）
  - `applyDate`（Computed when Composed = `@Created`）
  - `processStatus`（狀態機核心）
  - `approveNotesID` / `approveDate` / `memo`（審核結果）
- View：`V{AppPrefix}50 待審清單`，選擇公式
  `SELECT form="F{AppPrefix}05" & processStatus="待審核"`。
- Role（ACL 定義）：`[Approver]`、`[Admin]`。

## 狀態流程圖

```
[建立] applicant 填 F{AppPrefix}05
        processStatus := "待審核"（Computed when Composed）
        approveNotesID 等留空
            │
            ▼
[待審] 出現在 V{AppPrefix}50（依狀態過濾）
            │
   ┌────────┴─────────┐
   ▼                  ▼
[核准 Action]      [駁回 Action]   ← 僅 [Approver] 可見（Hide-When）
 processStatus="核准" processStatus="駁回"
 approveNotesID=審核人  同左
 approveDate=@Now       同左
 (可選) @MailSend 通知   同左
            │
            ▼
[結案] 離開 V{AppPrefix}50（不再符合 processStatus="待審核"）
```

## 步驟與程式碼

### 1. 建立時設初值（F{AppPrefix}05 欄位公式）

```formula
REM {processStatus，Computed when Composed};   "待審核"
REM {applyDate，Computed when Composed};        @Created
REM {displayName，Computed};
   tmp := @DbLookup(""\:"NoCache"; ""; "V{AppPrefix}03"; keyField; "displayName");
   @If(@IsError(tmp); ""; tmp)
```

### 2. 待審視圖（V{AppPrefix}50 選擇公式）

```formula
SELECT form = "F{AppPrefix}05" & processStatus = "待審核"
```
> 常見缺陷：誤寫成主檔的 `form="F{AppPrefix}01"`、或漏掉狀態過濾。務必校對。

### 3. 核准 / 駁回 Action（含 Role 控制顯示）

```formula
REM {Hide-When：非核准者、或非待審狀態即隱藏};
!@IsMember("[Approver]"; @UserRoles) | processStatus != "待審核"
```

```formula
REM {核准 Action click 公式};
FIELD processStatus := "核准";
FIELD approveNotesID := @Name([CN]; @UserName);
FIELD approveDate := @Now;
@Command([FileSave]); @Command([FileCloseWindow])
```

### 4.（可選）通知申請人

```formula
@MailSend(applicantMail; ""; ""; "您的申請已" + processStatus; "";
          "詳見系統。"; [IncludeDoclink])
```

## 閉環檢查（交付前）

- [ ] `processStatus` 由 Action/Agent 推進，非手動改欄位。
- [ ] 狀態變更同時寫審核人 + `@Now`。
- [ ] 待審視圖選擇公式對應正確 Form + 狀態字串（大小寫/全半形一致）。
- [ ] 敏感 Action 以 Role 控制顯示。
- [ ]（隱私需求）F{AppPrefix}05 加 Readers 欄位：`applicant : "[Approver]" : "[Admin]"`。
- [ ]（可選）通知機制可運作。
