# Implementation Plan: Todoアプリ コア機能（MVP＋段階拡張）

**Branch**: `001-todo-mvp` | **Date**: 2026-07-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-todo-mvp/spec.md`

## Summary

個人用Todoアプリのコア機能を、優先度付きストーリー（P1: 追加・完了・削除、P2: フィルタ、
P3: 名前編集、P4: 期限）として段階実装する。技術方針は「Flutter標準機能＋最小限の依存」:
状態管理はSDK内蔵の `ChangeNotifier`、永続化は `shared_preferences`（web では localStorage に
保存される）を採用し、期限切れ判定のために「現在時刻」を注入可能にしてテストを安定させる。

## Technical Context

**Language/Version**: Dart（SDK ^3.12.2）/ Flutter 3.44.6 stable

**Primary Dependencies**: Flutter（Material）＋追加依存は `shared_preferences` 1つのみ

**Storage**: `shared_preferences` 経由でブラウザの localStorage に JSON 文字列として保存
（スキーマは [contracts/storage-schema.md](./contracts/storage-schema.md)）

**Testing**: `flutter_test`。ユニットテスト（モデル・リポジトリ・コントローラ）＋
ウィジェットテスト（specの受け入れシナリオを網羅）。`SharedPreferences.setMockInitialValues`
で永続化をモック、注入した固定時刻で期限切れ判定をテスト

**Target Platform**: Web（PC の Chrome）。実行は `flutter run -d chrome`

**Project Type**: Single project（Flutter アプリ単体、バックエンドなし）

**Performance Goals**: タスク100件で一覧表示・各操作が体感遅延なし（SC-004）。
フィルタ切替は即時反映（SC-003）

**Constraints**: オフライン単体動作（外部サービス・ネットワーク通信なし）。
データはブラウザ内のみ（憲法「技術スタック制約」）

**Scale/Scope**: 単一ユーザー・最大数百件・1画面（一覧＝ホームのみ）＋4ユーザーストーリー

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 原則 | 判定 | 根拠 |
|------|------|------|
| I. 仕様が唯一の正 | ✅ PASS | 本planの全設計要素はspec.mdのFR/ストーリーに遡れる（data-model.mdにFR対応を明記） |
| II. テスト必須 | ✅ PASS | 各ストーリーにユニット＋ウィジェットテストを計画。時刻注入で期限テストを決定的にする。完了条件は `flutter test`・`flutter analyze` クリーン |
| III. 小さな単位 | ✅ PASS | P1→P4をストーリー単位で区切って実装・レビュー。tasksフェーズでストーリーごとにチェックポイントを置く |
| IV. 人間＝レビュー | ✅ PASS | 実装開始前にfeatureブランチを切り、ストーリー単位で人間レビューを経てからmainへ |
| V. シンプルさ | ✅ PASS | 状態管理はSDK内蔵`ChangeNotifier`（外部状態管理ライブラリなし）。追加依存は`shared_preferences`のみ（採用理由はresearch.md）。画面は1つ、ルーティングなし |

**Post-Phase 1 re-check**: ✅ PASS — 設計後も追加依存・追加レイヤーは発生していない。
エンティティ1つ・画面1つ・リポジトリ1つの最小構成を維持。

## Project Structure

### Documentation (this feature)

```text
specs/001-todo-mvp/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/
│   └── storage-schema.md  # 永続化データのスキーマ契約
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── main.dart                          # エントリポイント（既存scaffoldを置き換え）
├── models/
│   └── task.dart                      # Taskエンティティ＋JSON変換＋バリデーション
├── services/
│   └── task_repository.dart           # shared_preferencesへの保存/読込（スキーマv1）
├── controllers/
│   └── todo_list_controller.dart      # ChangeNotifier。タスク操作・フィルタ・期限切れ判定（時刻注入）
└── pages/
    └── home_page.dart                 # 一覧画面（入力欄・フィルタバー・タスクリスト）

test/
├── models/
│   └── task_test.dart                 # JSON往復・バリデーション
├── services/
│   └── task_repository_test.dart      # 保存/読込・壊れたデータの回復（FR-011）
├── controllers/
│   └── todo_list_controller_test.dart # 追加/完了/削除/編集/フィルタ/期限切れ（固定時刻）
└── pages/
    └── home_page_test.dart            # specの受け入れシナリオをウィジェットテストで検証
```

**Structure Decision**: Single project（Flutterアプリ単体）。`lib/` 配下を
models / services / controllers / pages の4層に分け、テストはミラー構成にする。
既存の `lib/main.dart`（カウンターscaffold）と `test/widget_test.dart` は置き換える。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

違反なし（記載事項なし）。
