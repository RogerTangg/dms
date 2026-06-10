# 已知問題與技術債型錄（Known Issues Catalogue）

> 萃取自來源專案的通用「易踩雷」型錄，依嚴重度分級。分析新專案時，比對是否存在
> 同類問題；切勿把「設計缺陷」當「既有規範」沿用。

## Critical（資料遺失 / 安全外洩等級）

- **無文件級安全卻含隱私資料** —— 無任何 Readers 欄位時，所有 Author 以上使用者可見
  全部文件。含個資/申請理由者屬高風險。解法見 `security-model.md` 第三節。

## Warning（功能不正確 / 流程斷裂）

- **W1 視圖選擇公式與用途不符** —— 視圖名為某型別、`SELECT` 卻過濾另一型別
  （複製貼上殘留的典型缺陷）。徵兆：視圖列出非預期文件、缺狀態過濾。
  解法：校正 `SELECT form = "正確代號" & 狀態過濾`，並確認欄位對應正確 Form。
- **W2 工作流未閉環** —— 狀態/審核人/時間欄位俱在，卻無 Action/Agent 推進狀態、
  無通知、無稽核。解法：加核准/駁回 Action 設狀態 + `@Now`，必要時通知。

## Info（技術債 / 易混淆點）

- **I1 欄位命名不一致** —— 英文與本地化欄名混用；`_1` 後綴欄位（命名衝突殘留，
  部分為死欄位）。陷阱：勿引用死欄位；新欄位一律英文 `camelCase`。
- **I2 缺乏輸入驗證** —— @DbLookup 查無 key 回 `@Error`，表單無防呆。解法：Input
  Validation + `@IsError` 包裝。
- **I3 LotusScript 無錯誤處理** —— 缺 `On Error GoTo`。解法：每進入點補上。
- **I4 程式碼未模組化** —— 無 Subform/Shared Action/Script Library，重複公式散落。
  成長後抽共用元素。
- **I5 設計版本標記落差** —— `$DesignerVersion` 低於 DB 版本，屬相容格式非錯誤。
- **I6 dbscript 為空** —— 無資料庫層級腳本事件（Postopen/Querysave…），新增全域邏輯時才用。

## 修改 DXL 的通用陷阱

- 切勿手動編輯 `$Body`、`$ViewFormat`、`$V5ACTIONS`、`$FrameSet`、`$SiteMapList`
  等 base64 二進位區塊（極易損毀）。佈局/欄位變更請在 Domino Designer 內完成。
- 修改後 `sign='true'` 元素須重新簽署。

> 對照用審核清單見 `scripts/design-audit-checklist.md`。
