# Formula 食譜（Formula Cookbook）

> 可重用的 `@Function` 片段。所有視圖名、欄位名為佔位符。

## 1. @DbLookup 帶值（核心模式）

```formula
@DbLookup(""\:"NoCache"; ""; "V{AppPrefix}03"; keyField; "displayName")
```
- 第一參數 `""\:"NoCache"`：`""`=本資料庫；`NoCache`=不取快取（主檔可能更新）。
- 第三參數 = lookup view 代號；第四 = key；第五 = 欲取欄位名（或欄位序號）。
- 跨庫：第一參數放伺服器、第二放資料庫路徑 ——
  `@DbLookup("Notes":"NoCache"; "Server/Org":"path\\other.nsf"; "viewName"; key; col)`。
  正式環境避免硬編碼伺服器/路徑，改用 profile/環境變數（見 integration-guide.md）。

## 2. @DbLookup 防呆包裝

```formula
tmp := @DbLookup(""\:"NoCache"; ""; "V{AppPrefix}03"; keyField; "displayName");
@If(@IsError(tmp); ""; tmp)
```
找不到 key 時回空字串而非 `@Error`。配合輸入驗證使用。

## 3. @DbColumn 動態選單

```formula
@Unique(@DbColumn(""\:"NoCache"; ""; "V{AppPrefix}02"; 2))
```
取視圖第 2 欄所有值作下拉選項，保持與既有資料一致（如分組、假別）。

## 4. 輸入驗證（Input Validation 公式）

```formula
@If(keyField = ""; @Failure("請輸入識別碼");
    @IsError(@DbLookup(""\:"NoCache"; ""; "V{AppPrefix}03"; keyField; "displayName"));
        @Failure("查無此資料，請確認識別碼");
    @Success)
```

## 5. 輸入轉換（Input Translation）

```formula
@Trim(@UpperCase(keyField))   REM {標準化 key：去空白、轉大寫};
```

## 6. 預設值與快照（Computed when Composed）

```formula
REM {processStatus 初值};        "待審核"
REM {applyDate 建立時快照};      @Created
REM {applicant 建立者快照};      @Name([CN]; @UserName)
REM {docNo 單號};               @Unique
```

## 7. 取現值 / 使用者 / 角色

```formula
@Now ; @Today ; @UserName ; @Name([CN]; @UserName)
@IsMember("[Approver]"; @UserRoles)      REM {是否具核准角色};
```

## 8. 條件式隱藏（Hide-When 公式）

```formula
REM {僅核准者看得到「核准」按鈕};
!@IsMember("[Approver]"; @UserRoles) | processStatus != "待審核"
```

## 9. 視圖選擇公式（Selection Formula）

```formula
SELECT form = "F{AppPrefix}05" & processStatus = "待審核"
```
- 保持單純；狀態字串須與表單寫入值完全一致（大小寫、全半形）。
- 隱藏 lookup view 用最單純 `SELECT form = "F{AppPrefix}01"`。

## 10. 視圖欄位公式（Column Formula）

```formula
REM {組合顯示};  studentID + " " + displayName
REM {狀態中文化};  @If(processStatus="待審核"; "⏳ 待審"; processStatus)
```

## 11. 通知（前端/公式 Agent）

```formula
@MailSend(approverName; ""; ""; "請假待審：" + displayName; ""; "請至系統審核";
          [IncludeDoclink])
```

## 12. @Command / @Commands（Notes Client 專屬，不可移植到 Web）

```formula
@Command([Compose]; "F{AppPrefix}05");
@Command([FileSave]); @Command([FileCloseWindow])
```
> 標記為 Client 專屬；Web/XPages 化時需改寫。見 integration-guide.md 現代化段落。
