# 整合與外部依賴（Integration Guide）

> 盤點與設計外部整合的通用指引。classic 小型應用多半僅有資料庫內 @DbLookup；
> 本文件同時涵蓋擴充與現代化時會用到的整合點。

## 一、資料庫內/跨庫查詢（@DbLookup / @DbColumn）

- **同庫**：第一參數 `""\:"NoCache"`、第二參數 `""`。
- **跨庫**：`@DbLookup("Notes":"NoCache"; serverName : dbPath; viewName; key; col)`。
- **反模式**：硬編碼 `serverName`/`dbPath`。改為：
  - Profile 文件（`@GetProfileField` / `NotesDatabase.GetProfileDocument`）；
  - 環境變數（`@Environment` / `notes.ini`，`NotesSession.GetEnvironmentString`）；
  - 設定文件（一筆 config form）。
- 盤點時 grep `@DbLookup`、`@DbColumn`、`GetDatabase`、`OpenDatabase` 找出所有外部庫引用。

## 二、ODBC / 關聯式資料庫

- LotusScript：LS:DO（`LCConnection`、`LCFieldlist`）或 `ODBCConnection`/`ODBCQuery`/
  `ODBCResultSet`（需 Lotus Connector / NotesSQL）。
- 用於與外部 RDBMS 雙向同步；連線字串、帳密**勿硬編碼**，放設定文件並加密。

## 三、LDAP / 目錄

- `NotesSession` + Directory；或透過 Domino Directory（`names.nsf`）查人員。
- 認證整合常經 Domino Directory / LDAP 目錄助手（Directory Assistance）。

## 四、Web Service

- **Provider**：以 Web Service 設計元素（LotusScript/Java）對外提供 SOAP。
- **Consumer**：Web Service Consumer 設計元素呼叫外部 SOAP。

## 五、REST / 現代化（HTTP）

- **Domino REST API（DRAPI，前身 Project KEEP）**：以設定將既有 .nsf 的文件/視圖
  以 REST 端點暴露，無需改寫資料模型 —— 是 classic 應用最低成本的 API 化路徑。
- **NotesHTTPRequest**（V10+）：LotusScript 內主動呼叫外部 REST。
- **XPages / SSJS**：若要 Web UI，可在同庫加 XPages 重用既有文件。
- **Nomad Web / Mobile**：讓既有 Notes Client UI 直接跑在瀏覽器/行動裝置，
  幾乎免改寫，是保留 Client UI 的快速上 Web 路徑。

## 六、其他整合

- `@URLOpen`、`@Command([...])`：Client 專屬，Web 不可移植。
- OLE / DDE / COM：舊式整合，現代化時優先以 REST 取代。
- DominoIQ（V14.5+）：內建 AI 推論，可用於分類/摘要等加值。

## 七、現代化決策速查

| 目標 | 建議路徑 |
|---|---|
| 既有資料對外提供 API | Domino REST API（DRAPI） |
| 既有 Client UI 上瀏覽器 | Nomad Web |
| 新 Web UI、重用資料 | XPages / Custom Controls |
| 主動呼叫外部服務 | NotesHTTPRequest / Web Service Consumer |
| 與 RDBMS 整合 | LS:DO / ODBC + 設定文件 |
| 全面脫離 Domino | 經 DRAPI 抽資料 → 目標平台（評估 @Command、Rich Text、NotesUI* 的不可移植性） |

> 評估可移植性時，標記所有 `NotesUIWorkspace`/`NotesUIDocument`/`@Command`/
> Rich Text 操作為 **Client 專屬**，需在遷移時改寫。
