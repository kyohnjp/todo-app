# Contract: 永続化ストレージスキーマ v1（001-todo-mvp）

**Date**: 2026-07-16 | **Consumer**: `TaskRepository` | **Data Model**: [data-model.md](../data-model.md)

このアプリが外部に公開する唯一のインターフェースは「ブラウザ内に保存するデータの形式」である。
将来バージョンのアプリが過去データを読めることを保証するため、ここで形式を契約として固定する。

## 保存先

- `shared_preferences` のキー **`todo_app.tasks`** に、以下のJSONオブジェクトを**文字列化して1件**保存する

## スキーマ（version 1）

```json
{
  "version": 1,
  "tasks": [
    {
      "id": 3,
      "title": "牛乳を買う",
      "isCompleted": false,
      "dueDate": "2026-07-20"
    },
    {
      "id": 4,
      "title": "レビュー依頼を出す",
      "isCompleted": true,
      "dueDate": null
    }
  ]
}
```

### フィールド仕様

| パス | 型 | 必須 | 説明 |
|------|-----|------|------|
| `version` | number | ✅ | スキーマ版数。本契約は `1` |
| `tasks` | array | ✅ | タスクの配列。**追加順（id昇順）で格納** |
| `tasks[].id` | number (int) | ✅ | 一意なタスクID |
| `tasks[].title` | string | ✅ | タスク名。trim後非空 |
| `tasks[].isCompleted` | boolean | ✅ | 完了状態 |
| `tasks[].dueDate` | string \| null | ✅（nullable） | 期限。`YYYY-MM-DD` 形式の日付のみ。期限なしは `null` |

## 読込時の規則（TaskRepositoryの契約）

1. キーが存在しない → 空一覧を返す（初回起動）
2. JSONとしてパース不能 → 空一覧を返す（クラッシュしない。FR-011）
3. `version` が `1` 以外／`tasks` が配列でない等の構造不正 → 空一覧を返す
4. 個々のタスク要素が不正（必須フィールド欠落・型不一致・`dueDate` が `YYYY-MM-DD` でない）
   → **その要素のみ読み飛ばし**、正常な要素は読み込む
5. 読み込んだタスクの最大 `id` は、次回採番の基準として利用できること

## 書込時の規則

1. タスクの追加・完了切替・削除・編集・期限変更のたびに全量を書き込む（research R6）
2. 書き込むJSONは本スキーマに完全準拠すること（`dueDate` の時刻部は保存前に落とす）

## 互換性ポリシー

- フィールドの追加・意味変更・削除を行う場合は `version` を上げ、新しい契約ファイルを作成する
- version 1 の読込コードは、将来のfeatureでも削除しない（旧データのマイグレーション経路として維持）
