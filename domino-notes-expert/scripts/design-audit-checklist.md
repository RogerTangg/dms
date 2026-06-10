# 設計審核檢查清單（Design Audit Checklist）

> 在交付 / 變更 classic Domino 應用前逐項核對。按本 skill 的 10 維度組織。
> 搭配 `references/known-issues.md` 對照常見缺陷。每項標記：✅通過 / ⚠️風險 / ❌缺陷。

## 維度 1：設計元素清單與分類
- [ ] 已列出所有 Forms / Views / Agents / Subforms / Pages / Framesets / Outlines。
- [ ] 每個元素標明用途、語言、被引用位置。
- [ ] 共用元素（Subform / Shared Action / Script Library）已識別其引用點。
- [ ] grep 驗證：`grep -rln "{AppPrefix}" .` 元素代號一致。

## 維度 2：資料模型
- [ ] 主檔與外鍵欄位已識別；關聯為 @DbLookup 鬆耦合或 Response（明確標示）。
- [ ] 每個欄位的型別與計算方式（Editable/Computed/CWC/Display）正確。
- [ ] 無 `_1` 死欄位被新程式引用；新欄位 `camelCase` 英文。
- [ ] 未超過 32K summary 限制（大量文字/多值欄位時檢查）。

## 維度 3：商業邏輯與流程
- [ ] 每個 Agent 的觸發方式、頻率、作用範圍明確。
- [ ] @DbLookup/@DbColumn 一律帶 `NoCache`，且有 `@IsError` 防呆。
- [ ] 工作流閉環：狀態有 Action 推進、寫審核人 + `@Now`。
- [ ] notes.ini / 環境變數使用已記錄。

## 維度 4：前端設計（UI/UX）
- [ ] 佈局方式（Table/Section/Tabs/Layout）一致。
- [ ] 標示 Client 專屬 vs Web 相容元素。
- [ ] CSS/JS/Image 資源已盤點。

## 維度 5：View / Folder
- [ ] **每個視圖的 `SELECT` 與其用途相符**（重點：避免 W1 選擇公式不符）。
- [ ] 排序/分類鍵正確；隱藏 lookup view 第一欄為 key 且未被更動欄序。
- [ ] Full-Text Search 依賴已識別。

## 維度 6：安全與權限
- [ ] ACL 層級與旗標適合環境（上線前收緊 `-Default-`、封鎖外網域）。
- [ ] 含隱私資料的表單有 Readers 欄位（列級隔離）。
- [ ] Role 已定義且以 `@UserRoles` 控管敏感 Action。
- [ ] 所有 `sign='true'` 元素以正式 ID 重新簽署。

## 維度 7：整合與外部依賴
- [ ] 所有外部庫 / ODBC / LDAP / Web Service / REST 引用已列出。
- [ ] **無硬編碼伺服器名 / 路徑 / 人名**（改用 profile/環境變數/設定文件）。

## 維度 8：排程與自動化
- [ ] 排程 Agent 的週期與目標伺服器明確；用 `Print` 寫 log。
- [ ] 事件觸發 Agent（new mail / doc update）已識別。
- [ ] Replication formula 篩選邏輯已記錄。

## 維度 9：程式碼品質與可維護性
- [ ] LotusScript 每進入點有 `On Error GoTo`。
- [ ] 重複邏輯已抽 Subform / Shared Action / Script Library。
- [ ] 命名慣例一致（見 naming-conventions.md）。
- [ ] 表單有輸入驗證；無未處理的 @Error。

## 維度 10：現代化潛力
- [ ] 標記不可移植項：`NotesUIWorkspace`/`NotesUIDocument`/`@Command`/Rich Text。
- [ ] 評估 DRAPI 可暴露的資料端點 / Nomad Web 可行性。
- [ ] 複雜度分級（低/中/高）已記錄。

## 交付前最終門檻
- [ ] 變更只在 Domino Designer 內動 base64 區塊（`$Body`/`$ViewFormat`/`$V5ACTIONS`…）。
- [ ] 受影響元素已重新簽署並在目標伺服器測試執行。
- [ ] 對照 `references/known-issues.md`，未把已知缺陷當規範沿用。
