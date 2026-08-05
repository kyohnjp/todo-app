# todo_app

仕様駆動開発（SDD: Spec-Driven Development）の「型」を習得するための練習用Todoアプリ。
Flutter（web）製で、[GitHub Spec Kit](https://github.com/github/spec-kit) のワークフローに
沿って、仕様→設計→タスク分解→実装（AI）→レビュー（人間）のサイクルで開発しています。

## 機能

- タスクの追加・完了チェック・削除（リロード後もブラウザ内に保持）
- すべて / 未完了 / 完了済み の表示フィルタ
- タスク名の編集（タスクをタップ）
- 期限（日付）の設定と期限切れタスクの強調表示

## 実行

```bash
flutter pub get
flutter run -d chrome
```

## テスト・静的解析

```bash
flutter test      # 全テスト（タスク完了の必須条件）
flutter analyze   # 静的解析（同上）
```

## リポジトリ構成

```
.specify/memory/constitution.md   # プロジェクト憲法（テスト必須・小さなPR・人間レビュー等）
specs/001-todo-mvp/               # 機能の仕様一式（spec / plan / tasks / 契約 / 検証手順）
lib/                              # 実装（models / services / controllers / pages のMVVM構成）
test/                             # lib/ をミラーしたテスト
docs/notes/                       # 学習メモ
```

開発の流れ・各文書の役割は [specs/001-todo-mvp/](specs/001-todo-mvp/) と
[憲法](.specify/memory/constitution.md) を参照してください。
1ユーザーストーリー = 1ブランチ = 1 PR = 1回の人間レビュー、で進めています。
