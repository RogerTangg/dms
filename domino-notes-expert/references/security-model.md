# 安全模型（Security Model）

> 通用 Domino 安全分層樣板。實際 ACL 條目、Role 名稱依目標專案調整。

## 一、三層存取控制

```
ACL（資料庫層）── 決定每個人/伺服器/群組的基準層級
   └─ Reader/Author 欄位（文件層）── 決定誰能看/編單一文件（列級隔離）
         └─ Roles（功能/欄位層）── 以 @UserRoles 判斷特定動作/欄位授權
```

## 二、ACL 層級與旗標

| 層級 | 能力概要 |
|---|---|
| Manager | 完整控制，含改 ACL、刪設計 |
| Designer | 改設計元素 |
| Editor | 編輯所有文件 |
| Author | 建立並編輯**自己建立**的文件（需 Author 欄位配合） |
| Reader | 只讀 |
| Depositor | 只能建立、不能讀 |
| No Access | 無存取 |

常見旗標：`createdocs`、`deletedocs`、`writepublicdocs`、`createpersonalagents`、
`createpersonalviews`、`createlsjavaagents`。`maxinternetaccess` 限制 Web 使用者上限。

**建議**：
- 訓練/示範庫常見 `-Default-`=Author 的寬鬆設定，**上線前收緊**（多數使用者降為
  Reader 或 Author + 嚴格 Author 欄位）。
- 跨網域伺服器（`OtherDomainServers`）設 `No Access`。
- `adminserver` 指定管理伺服器以統一 ACL/欄位加密。

## 三、文件級安全（Reader / Author 欄位）

- **Readers 欄位**：限制哪些人/群組/Role 看得到該文件。**只要文件存在任一 Readers
  欄位，未列名者即看不到**（含視圖中也不顯示）。
- **Authors 欄位**：讓 ACL 為 Author 層級者能編輯**非自己建立**但被授權的文件。
- 兩者值須含**人名、群組名或 Role**（`[RoleName]`）。

**最大陷阱**：若沒有任何 Readers 欄位，所有 Author 以上使用者可見全部文件。
凡含隱私資料的表單（如申請理由、個資），加 Readers 欄位：
`申請人 : 審核者群組 : "[Admin]"`。

```formula
REM {Readers 欄位（型別 Readers）的 Computed 值};
applicant : "[Approver]" : "[Admin]"
```

## 四、Roles（角色）與 RBAC

- 在 ACL 定義 `[Admin]`、`[Approver]` 等 Role，指派給人/群組。
- 公式判斷：`@IsMember("[Approver]"; @UserRoles)`。
- LotusScript 判斷：`If session.UserRoles ... ` 或檢查 `Evaluate`。
- **先定義 Role 再建簽核閘門**；用 Role 控制 Action 顯示（隱藏公式）與
  `processStatus` 變更權限。

## 五、Section Access、ECL、加密

- **Controlled Access Section**：以公式限定某段落可編輯者。
- **ECL（Execution Control List）**：客戶端工作站控制可執行的簽署程式碼來源。
- **加密**：欄位加密（Secret/Public key）、文件加密；郵件/網路傳輸加密。

## 六、Agent 簽署與執行權限

- 設計元素 `sign='true'` 的 item 修改後**須重新簽署**（`wassignedby` 記錄簽署者）。
- 受限代理（`$Restricted=1`）需簽署者於伺服器具對應執行權（`Run restricted/unrestricted
  LotusScript/Java agents` 設定）。
- 上線時以**正式生產 ID** 重新簽署所有 Agent，避免以開發者個人 ID 簽署。

## 七、安全建議優先序（通用）

1. **（高）** 含隱私資料的表單加 Readers 欄位做列級隔離。
2. **（中）** 定義審核 Role + 以 Role 控管狀態變更與敏感 Action。
3. **（中）** 上線前收緊 `-Default-` 與 `maxinternetaccess`。
4. **（低）** 全部 Agent 以正式 ID 重新簽署、檢視 ECL。
