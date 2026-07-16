# Research: Todoアプリ コア機能（001-todo-mvp）

**Date**: 2026-07-16 | **Plan**: [plan.md](./plan.md)

Technical Contextに NEEDS CLARIFICATION は残っていないため、本書は主要な技術判断の
「決定・理由・却下した代替案」を記録する。

## R1. 永続化: shared_preferences を採用

- **Decision**: `shared_preferences` パッケージを追加し、タスク一覧をJSON文字列1件として保存する
- **Rationale**:
  - Flutter公式管轄（flutter.dev推奨のfirst-partyプラグイン）で、webでは localStorage に保存される＝specの「ブラウザに保持」を最短で満たす
  - `SharedPreferences.setMockInitialValues()` が標準で用意されており、ユニットテストが容易（憲法II）
  - 数百件規模のTodoにはKVストアで十分
- **Alternatives considered**:
  - `dart:html` / `package:web` の localStorage 直叩き → web専用コードになりテスト・移植性が悪い。却下
  - `hive` / `drift`（DB系）→ 数百件のタスクにDBは過剰（憲法V: 過剰設計の禁止）。却下
  - メモリのみ → spec FR-005（リロード後保持）を満たせない。却下

## R2. 状態管理: SDK内蔵の ChangeNotifier を採用

- **Decision**: `TodoListController extends ChangeNotifier` を1つ作り、`ListenableBuilder` でUIに反映。外部状態管理ライブラリは入れない
- **Rationale**:
  - 1画面・1エンティティのアプリに riverpod/bloc は過剰（憲法V）
  - ChangeNotifierはFlutter SDK内蔵＝依存ゼロ、かつコントローラ単体でユニットテスト可能（憲法II）
  - ロジック（追加/完了/削除/編集/フィルタ/期限判定）をUIから分離でき、ウィジェットテストの前にロジックだけ検証できる
- **Alternatives considered**:
  - `StatefulWidget` の setState のみ → ロジックがUIに癒着し、ユニットテストしづらい。却下
  - riverpod / provider / bloc → 学習・依存コストに見合う複雑さがない。却下

## R3. 期限切れ判定: 現在時刻の注入

- **Decision**: `TodoListController` にコンストラクタで `DateTime Function() now`（デフォルトは `DateTime.now`）を注入する。期限切れ判定は「タスクの期限日 < now()の日付」（日単位比較、当日は期限切れ扱いしない）
- **Rationale**: テストで固定時刻を渡せば期限切れテストが日によって壊れない（決定的テスト、憲法II）。specのUS4-3/4-4（昨日=期限切れ、明日=正常）がそのまま検証できる
- **Alternatives considered**:
  - テスト内で `DateTime.now()` に依存 → 実行日で結果が変わりflakyになる。却下
  - `clock` パッケージ → 関数注入1つで足りるため依存追加は不要（憲法V）。却下

## R4. タスクID: 単調増加の整数ID

- **Decision**: 各タスクに `id`（int）を持たせる。採番は「保存済みの最大id＋1」をリポジトリ層ではなくコントローラが管理（`_nextId`）。IDは永続化に含める
- **Rationale**: 編集・削除・完了切替の対象特定に、リスト添字ではなく安定IDが必要（フィルタ表示中は添字がズレるため）。UUIDは依存追加または乱数が必要で過剰
- **Alternatives considered**:
  - リスト添字で操作 → フィルタ表示（US2）と組み合わせるとバグの温床。却下
  - `uuid` パッケージ → 単一ユーザー・ローカルのみで衝突リスクなし、依存追加は不要。却下

## R5. 保存スキーマ: バージョン付きJSON

- **Decision**: 保存データはトップレベルに `version: 1` を持つJSONオブジェクトとし、読込時に版数チェック。パース不能・不正構造なら空一覧で起動（FR-011）。詳細は [contracts/storage-schema.md](./contracts/storage-schema.md)
- **Rationale**: 将来のfeature（タグ・優先度等）でスキーマが変わってもマイグレーション判定ができる。壊れたデータでのクラッシュ防止はspecのEdge Case要件
- **Alternatives considered**:
  - 素のJSON配列のみ → 将来の変更時に版数判定ができない。versionフィールド1つのコストで回避できるため却下

## R6. 保存タイミング: 変更のたびに全量保存

- **Decision**: 追加・完了切替・削除・編集・期限変更のたびに、タスク全件をJSONにして保存する（書き込みは非同期、UIはメモリ上の状態で即時反映）
- **Rationale**: 数百件×短い文字列なら全量書き込みで性能問題なし（SC-003/004）。差分保存はKVストアでは実装が複雑になるだけ（憲法V）
- **Alternatives considered**:
  - 明示的な保存ボタン → 個人用ツールのUXとして煩雑、保存忘れでFR-005違反リスク。却下
