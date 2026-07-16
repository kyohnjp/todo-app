# Data Model: Todoアプリ コア機能（001-todo-mvp）

**Date**: 2026-07-16 | **Plan**: [plan.md](./plan.md) | **Spec**: [spec.md](./spec.md)

## Entity: Task

やること1件を表す唯一のエンティティ。親子・依存関係なし（spec Key Entities）。

| フィールド | 型 | 必須 | 制約 | 由来 |
|-----------|-----|------|------|------|
| `id` | int | ✅ | 一意・不変。コントローラが単調増加で採番（research R4） | 操作対象の特定（FR-003/004/007/008） |
| `title` | String | ✅ | trim後に空であってはならない。文字数上限なし（長文は表示側で折り返し） | FR-001/002、Edge Case（200文字） |
| `isCompleted` | bool | ✅ | デフォルト false | FR-003 |
| `dueDate` | DateTime? | — | null=期限なし。日付のみ有効（時刻部は正規化して無視） | FR-008、Assumption（時刻なし） |

### バリデーション規則

- **V1**: `title.trim().isEmpty` となる追加・編集は拒否する（FR-002）。拒否時は状態を変更しない
- **V2**: 同名タスクは許容する（Assumption: 重複OK）。一意性チェックは行わない
- **V3**: `dueDate` は過去日付も許容する（Edge Case: 設定自体は可、期限切れ表示になる）

### 導出プロパティ（保存しない）

- **`isOverdue(DateTime today)`**: `dueDate != null && !isCompleted && dueDate(日付部) < today(日付部)`
  - 当日が期限のタスクは期限切れ**ではない**
  - 完了済みタスクは期限が過去でも期限切れ扱いしない（FR-009、US4-4）
  - `today` は注入された現在時刻から得る（research R3）

### 状態遷移

```
未完了 ──完了チェック──▶ 完了
  ▲                        │
  └────チェック解除────────┘
```

- 編集（title変更）・期限の設定/変更/解除は完了状態に影響しない（FR-007/008）
- 削除はどちらの状態からでも可能（FR-004）

## 値: TaskFilter（表示フィルタ）

タスクの属性ではなく画面の表示状態。**永続化しない**（リロード後は初期値に戻る）。

| 値 | 表示対象 | 由来 |
|----|---------|------|
| `all`（初期値） | 全タスク | FR-006 |
| `active` | `isCompleted == false` | FR-006 |
| `completed` | `isCompleted == true` | FR-006 |

## コレクションの規則

- 一覧は追加順（`id` 昇順と一致）で保持・表示する（FR-010）。並び替えなし
- フィルタは表示の絞り込みのみで、元データの順序・内容を変えない

## 永続化マッピング

- Task⇄JSONの対応と保存全体の構造は [contracts/storage-schema.md](./contracts/storage-schema.md) を正とする
- 読込失敗（キー不在以外のパース不能・構造不正・未知version）→ 空一覧＋採番リセットで起動（FR-011）
