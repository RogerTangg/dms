# LotusScript 食譜（LotusScript Cookbook）

> 可重用後端片段。物件變數命名沿用慣例：`ss`(NotesSession)、`ws`(NotesUIWorkspace)、
> `db`(NotesDatabase)、`dc`(NotesDocumentCollection)、`doc`(NotesDocument)、`view`(NotesView)。

## 1. 標準 Agent 骨架（含錯誤處理）

```lotusscript
Sub Initialize
    On Error GoTo errHandler            ' legacy 代理常缺此行，務必補上
    Dim ss As New NotesSession
    Dim db As NotesDatabase
    Set db = ss.CurrentDatabase
    ' ...邏輯...
    Exit Sub
errHandler:
    MessageBox "錯誤 " & Err & " (行 " & Erl & "): " & Error$, , "A{AppPrefix}NN"
    Exit Sub
End Sub
```
> 分區順序由 Designer 自動產生：`(Options)` / `(Forward)` / `(Declarations)` / `Initialize`。

## 2. 選取文件批次戳記（手動代理）

```lotusscript
Sub Initialize
    On Error GoTo errHandler
    Dim ss As New NotesSession
    Dim db As NotesDatabase
    Dim dc As NotesDocumentCollection
    Set db = ss.CurrentDatabase
    Set dc = db.UnprocessedDocuments      ' 手動代理 = 使用者選取集
    If dc.Count = 0 Then Exit Sub

    Dim val As String
    val = InputBox$("請輸入值", "批次設定")
    If val = "" Then Exit Sub

    Call dc.StampAll("targetField", val)  ' 一次寫入、免逐筆 Save
    Exit Sub
errHandler:
    MessageBox "錯誤 " & Err & ": " & Error$ : Exit Sub
End Sub
```
> 比逐筆 `doc.Save` 高效。觸發設為手動（`$AssistTrigger=4`）、受限（`$Restricted=1`）。

## 3. 逐筆處理集合（需個別邏輯時）

```lotusscript
Dim doc As NotesDocument
Set doc = dc.GetFirstDocument
While Not doc Is Nothing
    doc.processStatus = "核准"
    doc.approveDate = ss.CreateDateTime(Format(Now, "yyyy-mm-dd"))
    Call doc.Save(True, False)
    Set doc = dc.GetNextDocument(doc)
Wend
```

## 4. 經 View 查單一文件（後端 lookup）

```lotusscript
Dim view As NotesView
Set view = db.GetView("V{AppPrefix}03")
Dim master As NotesDocument
Set master = view.GetDocumentByKey(keyValue, True)   ' True=精確比對
If Not master Is Nothing Then displayName = master.displayName(0)
```

## 5. 排程代理樣板（Scheduled Agent）

```lotusscript
Sub Initialize
    On Error GoTo errHandler
    Dim ss As New NotesSession
    Dim db As NotesDatabase
    Set db = ss.CurrentDatabase
    ' 以 db.Search / db.GetView 取得待處理文件後處理（歸檔、彙整、清理）
    Exit Sub
errHandler:
    Print "Agent error " & Err & ": " & Error$    ' 排程代理用 Print 寫 log
End Sub
```
> 排程代理在伺服器執行：用 `Print`（寫入伺服器 log）而非 `MessageBox`；
> 觸發設 On Schedule，指定目標伺服器與週期。

## 6. 發送通知

```lotusscript
Dim memo As NotesDocument
Set memo = db.CreateDocument
memo.Form = "Memo"
memo.SendTo = approverName
memo.Subject = "待審：" & displayName
Call memo.Send(False)
```

## 7. 前端互動（NotesUIDocument，Client 專屬）

```lotusscript
Dim ws As New NotesUIWorkspace
Dim uidoc As NotesUIDocument
Set uidoc = ws.CurrentDocument
Call uidoc.FieldSetText("processStatus", "核准")
Call uidoc.Refresh
```
> `NotesUIWorkspace`/`NotesUIDocument` 不可在伺服器/排程/Web 執行 —— 現代化時改後端類別。

## 通用守則
- 每個進入點加 `On Error GoTo`。
- 早期 `Exit Sub` 守衛（空集合、空輸入）。
- 批次優先 `StampAll`；個別邏輯才迴圈。
- 重複邏輯抽 Script Library，以 `Use "libName"` 引用。
