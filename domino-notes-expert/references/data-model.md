# 資料模型（Data Model）

> 本文件提供 classic Domino 應用的**通用資料模型樣板**。所有 `{AppPrefix}`、欄位名、
> 視圖名皆為佔位符，套用時以目標專案的實際代號取代。範例慣例萃取自一個以 Formula +
> 少量 LotusScript 實作的學生出勤簽到系統（Domino 12.0.2）。

## 一、文件型別與 Form 對應

每一種文件型別對應一個 Form。先盤點文件型別，挑出一個**主檔（master form）**，
其餘文件透過邏輯外鍵參照主檔。典型四類：

| 文件型別 | 角色 | 樣板代號 |
|---|---|---|
| 主檔（人員/資源/品項） | 被其他文件 @DbLookup 引用 | `F{AppPrefix}01` |
| 設定/排程檔 | 獨立資料 | `F{AppPrefix}02` |
| 交易/紀錄檔 | 開單時帶入主檔欄位 | `F{AppPrefix}03` |
| 流程/申請檔 | 含狀態欄位、走簽核 | `F{AppPrefix}05` |

> 編號可不連續（缺 `04` 屬正常，通常為開發過程刪除）。

## 二、欄位型別與計算方式

DXL 中欄位以 `placeholder` item 或具值 item 宣告；日期時間欄位以
`<rawitemdata type='400'>` 標示（TIME 型別）。建立欄位時明確選定**型別**與**計算方式**：

| 型別 | 用途 | DXL 線索 |
|---|---|---|
| Text | 一般文字、代碼 | `type='0'` placeholder |
| Number | 數量、金額（可設預設值） | `<number>0</number>` |
| DateTime | 日期/時間 | `type='400'` |
| Rich Text | 附件、格式內文 | CD 記錄於 `$Body` |
| Names / Authors / Readers | 人員、文件級存取控制 | 見 security-model.md |

| 計算方式 | 何時用 |
|---|---|
| Editable | 使用者輸入 |
| Computed | 每次開啟/存檔重算（適合 @DbLookup 帶值，主檔變動會更新） |
| Computed for Display | 僅顯示、不存入文件 |
| Computed when Composed | 僅建立時計算一次（適合快照、單號、建立者） |

**原則**：帶入會變動的主檔資料用 `Computed`；要凍結成快照（如核准當下的金額）用
`Computed when Composed`。

## 三、文件關聯：外鍵 + Lookup View（非 Response 階層）

classic 應用常見的可維護模式是**鬆耦合外鍵**而非 Notes Response 父子文件：

```
F{AppPrefix}01 (主檔)
   keyField  ──(@DbLookup 經 V{AppPrefix}03)──▶  F{AppPrefix}03.keyFieldRef
                                              └─▶  F{AppPrefix}05.keyField
```

- 在主檔放一個邏輯主鍵欄位（`keyField`，例：人員識別碼）。
- 建一個**隱藏 lookup view**（`V{AppPrefix}03`），第一欄即 `keyField`（排序），
  後續欄放要被帶出的欄位。
- 子文件以 `@DbLookup(""\:"NoCache"; ""; "V{AppPrefix}03"; keyField; "欲取欄位")` 帶值。

優點：文件互相獨立、不依賴實體父子鏈、易於重建索引、語意接近關聯式 join。
新增「需要主檔資料」的文件型別時，**重用同一 lookup view 與 key**，不要另建平行 lookup，
也不要改用 Response 文件（除非真有階層展開需求）。詳見 design-patterns.md。

> ⚠️ Lookup view 的**欄位順序即契約**：更動第一排序欄或欄序會破壞所有 @DbLookup 帶值公式。

## 四、欄位命名（套用時統一）

- 新欄位一律 `camelCase` 英文：`studentNotesID`、`projectGroup`、`leaveDateFrom`。
- 外鍵欄位跨表單**同名**（如統一用某個 `keyField`）。
- 狀態欄位 `XxxStatus`；日期 `XxxDate`；時間 `XxxTime`。
- 反模式（勿仿效）：本地化中文欄名、`_1` 自動後綴欄位（命名衝突殘留）。詳見
  naming-conventions.md 與 known-issues.md。

## 五、32K Summary 限制

DXL 屬性 `$LargeSummary=0` 時，單一文件所有**非 Rich Text** 欄位合計 summary data
受 32K 限制（被視圖欄/排序引用的欄位均計入）。欄位少時無風險；大量文字/多值欄位、
或視圖顯示眾多欄位時需留意，必要時開啟 LargeSummary 或將大文字改為 Rich Text。

## 六、最小可用樣板（依本文件命名）

| 欄位 | 型別 | 計算 | 說明 |
|---|---|---|---|
| `keyField` | Text | Editable（主檔）/ Editable（子檔輸入） | 邏輯外鍵 |
| `displayName` | Text | Computed（子檔，由 @DbLookup 帶入） | 帶出的主檔欄位 |
| `recordDate` | DateTime(`400`) | Editable | 交易日期，視圖分類鍵 |
| `processStatus` | Text | Editable | 流程狀態機核心欄位 |
| `approveDate` | DateTime(`400`) | Computed when Composed / 由 Action 設 | 核准時間快照 |

對應的可直接調整的 Form DXL 範例見 `examples/form-template.dxl`。
