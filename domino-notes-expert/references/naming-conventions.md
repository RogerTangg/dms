# 命名慣例與編碼規範（Naming Conventions）

> 套用時以目標專案實際代號取代佔位符；若目標專案已有慣例，沿用其慣例。

## 一、設計元素命名

格式：`{TypeLetter}{AppPrefix}{NN}`

| TypeLetter | 類型 |
|---|---|
| `F` | Form |
| `V` | View |
| `A` | Agent |
| `S` | Subform |
| `P` | Page |

- `AppPrefix`：短固定應用代碼（2–4 字母），全應用一致、勿更改。
- `NN`：兩位數序號，**可不連續**（刪除留缺號屬正常）。
- 公式/腳本中**一律以代號參照**元素，不用本地化全名。

## 二、$TITLE 與別名

- Form / View 標題以 `|` 分隔「人類可讀名」與「代號別名」：
  - Form：`$TITLE` 含 `{Code} 中文名稱` 與 `{Code}` 兩值。
  - View：`{Code} 主題\子分類|{Code}`。
- **View 選單分層用反斜線 `\`**（`主題\子分類`）。
- 隱藏 lookup view 設隱藏旗標（`$Flags` 含 `P`），不出現在選單。

## 三、欄位命名

- 新欄位一律 `camelCase` 英文：`studentNotesID`、`projectGroup`、`leaveDateFrom`。
- 語意後綴：狀態 `XxxStatus`、日期 `XxxDate`、時間 `XxxTime`、是否 `isXxx`。
- 邏輯外鍵跨表單**同名**。
- **反模式（勿製造）**：
  - 本地化中文欄名（既有專案可能有，新欄位不仿效）。
  - `_1` 自動後綴欄位 —— 來自命名衝突，部分為死欄位；解決衝突而非沿用。

## 四、DateTime 與型別線索（DXL）

- DateTime 欄位在 DXL 以 `<rawitemdata type='400'>` 表示。
- Number 預設值以 `<number>…</number>`；Text placeholder 以 `type='0'`。
- 各 Form 的欄位清單在 `$Fields` item（textlist）。

## 五、DXL / ODP 維護規範

- **可安全文字審閱/小改**：視圖 `$Formula`、`$SelQuery`、`$TITLE`、`$Flags`、
  Agent LotusScript（仍須在 Designer 重編譯）。
- **切勿手動編輯**（base64 二進位 CD 記錄，極易損毀）：`$Body`、`$ViewFormat`、
  `$V5ACTIONS`、`$FrameSet`、`$SiteMapList`、`$Collation`、`IconBitmap`。
- 佈局/欄位/動作鈕變更一律在 **Domino Designer** 內完成，再匯出 DXL。
- 任何 `sign='true'` 的 item 修改後**須重新簽署**。

## 六、版本相容

- 留意 `$DesignerVersion`（元素標記的 Designer 版本）可能低於資料庫 ODS/DXL 版本
  （例：元素 `8.5.3` vs DB Domino 12.0.2 / ODS 53）——屬向後相容格式，非錯誤。
- 新增元素維持與既有相容，避免引入僅高版本支援的特性而造成混淆。

## 七、grep 速查樣式

```
grep -rl "V{AppPrefix}03"  Views/        # 找引用某 lookup view 者
grep -rln "@DbLookup"      Forms/ Views/ # 所有帶值/查詢點
grep -rln "type='400'"     Forms/        # DateTime 欄位
grep -rl  "form = \"F{AppPrefix}"        # 視圖選擇公式對應
```
