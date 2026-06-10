'==============================================================================
' 標準 LotusScript Agent 範本：選取文件批次戳記（含錯誤處理）
'------------------------------------------------------------------------------
' 來源模式：選取 → UnprocessedDocuments → StampAll（見 references/design-patterns.md P2）。
' 觸發設定：手動（Actions 選單）/ 作用於選取文件（$AssistTrigger=4、$Restricted=1）。
' 套用時替換 "targetField"、提示字串、Agent 代號 A{AppPrefix}NN。
'
' 與來源專案差異：來源原始碼「無」On Error；本範本補上錯誤處理（改進方向）。
' 為何用 StampAll：一次寫入所有選取文件、免逐筆 doc.Save，效能遠優於迴圈。
'==============================================================================

Option Public
Option Declare

Sub Initialize
    On Error GoTo errHandler

    Dim ss As New NotesSession
    Dim db As NotesDatabase
    Dim dc As NotesDocumentCollection

    Set db = ss.CurrentDatabase
    Set dc = db.UnprocessedDocuments      ' 手動代理中 = 使用者選取集

    ' 守衛：無選取則結束
    If dc.Count = 0 Then
        MessageBox "請先選取文件。", , "A{AppPrefix}NN"
        Exit Sub
    End If

    ' 取得欲寫入的值
    Dim val As String
    val = InputBox$("請輸入要套用的值：", "批次設定")

    ' 守衛：取消或空輸入則結束
    If Trim(val) = "" Then Exit Sub

    ' 批次寫入單一欄位（高效）
    Call dc.StampAll("targetField", val)

    MessageBox "已更新 " & dc.Count & " 筆文件。", , "A{AppPrefix}NN"
    Exit Sub

errHandler:
    MessageBox "錯誤 " & Err & " (行 " & Erl & "): " & Error$, , "A{AppPrefix}NN"
    Exit Sub
End Sub

'------------------------------------------------------------------------------
' 變體：需要逐筆套用個別邏輯時（無法用 StampAll 的情況）
'------------------------------------------------------------------------------
' Dim doc As NotesDocument
' Set doc = dc.GetFirstDocument
' While Not doc Is Nothing
'     doc.processStatus = "核准"
'     doc.approveDate = ss.CreateDateTime(Format$(Now, "yyyy-mm-dd hh:nn:ss"))
'     Call doc.Save(True, False)
'     Set doc = dc.GetNextDocument(doc)
' Wend
'------------------------------------------------------------------------------
' 排程代理請改用 Print（寫伺服器 log）而非 MessageBox，並將觸發設為 On Schedule。
'==============================================================================
