# Tasks: Todoアプリ コア機能（MVP＋段階拡張）

**Input**: Design documents from `/specs/001-todo-mvp/`

**Prerequisites**: plan.md, spec.md, data-model.md, contracts/storage-schema.md, research.md, quickstart.md

**Tests**: 憲法Principle II（テスト必須・NON-NEGOTIABLE）により全ストーリーでテスト先行。
テストを先に書いて失敗を確認してから実装する。各タスク完了条件 = `flutter test` と `flutter analyze` クリーン。

**Organization**: ユーザーストーリー単位でフェーズを区切り、**1ストーリー = 1 featureブランチ = 1 PR = 1回の人間レビュー**とする（憲法III/IV）。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列実行可能（別ファイル・未完了タスクへの依存なし）
- **[Story]**: 対応するユーザーストーリー（US1〜US4）
- 各タスクに正確なファイルパスを記載

## Path Conventions

- Single project（Flutterアプリ単体）: `lib/`、`test/` はリポジトリ直下
- 構成の詳細は [plan.md](./plan.md) の Project Structure を正とする

---

## Phase 1: Setup（プロジェクト初期化）

**Purpose**: 依存の追加とscaffoldの整理

- [x] T001 `pubspec.yaml` に `shared_preferences` を追加し `flutter pub get` を実行
- [x] T002 scaffoldの `test/widget_test.dart`（カウンターテスト）を削除（US1で実テストに置き換わるまでテスト0件になるが、`lib/main.dart` の置き換え（T011）まではanalyzeが通ることを確認）

---

## Phase 2: Foundational（全ストーリーの前提・ブロッキング）

**Purpose**: 全ストーリーが依存するTaskモデルと永続化層。ストレージ契約 v1 は期限フィールドを含むため、モデルのJSON対応はここで完成させる（isOverdue判定ロジックのみUS4に置く）

**⚠️ CRITICAL**: このフェーズ完了までユーザーストーリーの実装を開始しない

- [x] T003 [P] Taskモデルのテストを作成（JSON往復・`dueDate` null/日付の両対応・title検証の素材）in `test/models/task_test.dart` — **先に書き、失敗を確認**
- [x] T004 Taskモデルを実装（`id`/`title`/`isCompleted`/`dueDate`、`toJson`/`fromJson`、data-model.mdのV1〜V3準拠）in `lib/models/task.dart`
- [x] T005 [P] TaskRepositoryのテストを作成（保存→読込の往復、キー不在→空、パース不能→空、構造不正→空、不正要素の読み飛ばし = contracts/storage-schema.md 読込規則1〜5）in `test/services/task_repository_test.dart` — **先に書き、失敗を確認**
- [x] T006 TaskRepositoryを実装（キー `todo_app.tasks`、スキーマv1準拠の読込/全量書込）in `lib/services/task_repository.dart`

**Checkpoint**: `flutter test`・`flutter analyze` クリーン → 基盤完成。ここまでを最初のPRに含める（US1と同一PRでも可）

---

## Phase 3: User Story 1 - 基本のタスク管理（追加・完了・削除） (Priority: P1) 🎯 MVP

**Goal**: タスクの追加・完了切替・削除ができ、リロード後も状態が残る（spec US1、FR-001〜005/010/011）

**Independent Test**: quickstart.md「US1」の手順 — タスク追加→完了→削除→リロードで状態復元、空入力拒否

### Tests for User Story 1（憲法II: 必須・実装より先）⚠️

- [x] T007 [P] [US1] TodoListControllerのユニットテストを作成（初期ロード、add/toggle/remove、空・空白title拒否で状態不変、採番の単調増加、操作ごとの保存呼び出し）in `test/controllers/todo_list_controller_test.dart` — **失敗を確認**
- [x] T008 [P] [US1] ホーム画面のウィジェットテストを作成（spec US1受け入れシナリオ1〜6: 追加表示・完了の見た目区別・チェック解除・削除・空入力無視、＋タスク0件時の空状態表示）in `test/pages/home_page_test.dart` — **失敗を確認**

### Implementation for User Story 1

- [x] T009 [US1] TodoListController（ChangeNotifier）を実装（リポジトリ注入、tasks公開、add/toggleCompleted/remove、変更ごとに非同期保存）in `lib/controllers/todo_list_controller.dart`
- [x] T010 [US1] ホーム画面を実装（入力欄＋追加、タスク一覧、完了チェックボックス＋打ち消し表示、削除ボタン、空状態表示）in `lib/pages/home_page.dart`
- [x] T011 [US1] `lib/main.dart` をエントリポイントとして置き換え（MaterialApp、リポジトリ＋コントローラの生成とHomePageへの接続）
- [x] T012 [US1] 検証ゲート: `flutter analyze` && `flutter test` クリーン、quickstart.md「US1」手動シナリオをChromeで実施

**Checkpoint**: featureブランチ `feat/us1-basic-tasks` からPR作成 → 人間レビュー → mainへマージ。**これ単体でMVP**

---

## Phase 4: User Story 2 - 完了/未完了フィルタ (Priority: P2)

**Goal**: すべて/未完了/完了済みの表示切替（spec US2、FR-006）。フィルタは永続化しない（初期値「すべて」）

**Independent Test**: quickstart.md「US2」— 完了2件・未完了3件で各フィルタの表示件数を確認

### Tests for User Story 2（憲法II: 必須・実装より先）⚠️

- [ ] T013 [P] [US2] コントローラのフィルタテストを追加（TaskFilter切替でvisibleTasksが正しく絞られる、初期値all、フィルタが元データを変更しない）in `test/controllers/todo_list_controller_test.dart` — **失敗を確認**
- [ ] T014 [P] [US2] フィルタのウィジェットテストを追加（spec US2受け入れシナリオ1〜4: 各フィルタの表示内容、未完了表示中の完了操作で一覧から消える、初期選択=すべて、絞り込み結果0件時の空表示）in `test/pages/home_page_test.dart` — **失敗を確認**

### Implementation for User Story 2

- [ ] T015 [US2] コントローラにTaskFilterとvisibleTasksを実装 in `lib/controllers/todo_list_controller.dart`
- [ ] T016 [US2] ホーム画面にフィルタバー（すべて/未完了/完了済み）を実装 in `lib/pages/home_page.dart`
- [ ] T017 [US2] 検証ゲート: analyze/test クリーン、quickstart.md「US2」手動シナリオ実施

**Checkpoint**: ブランチ `feat/us2-filter` からPR → レビュー → マージ

---

## Phase 5: User Story 3 - タスク名の編集 (Priority: P3)

**Goal**: 登録済みタスクの名前だけを修正できる（spec US3、FR-002/007）

**Independent Test**: quickstart.md「US3」— 名前編集の反映・空文字拒否・リロード後の保持

### Tests for User Story 3（憲法II: 必須・実装より先）⚠️

- [ ] T018 [P] [US3] コントローラのrenameテストを追加（title変更、完了状態・期限に影響しない、空・空白は拒否で元の名前維持、保存される）in `test/controllers/todo_list_controller_test.dart` — **失敗を確認**
- [ ] T019 [P] [US3] 編集のウィジェットテストを追加（spec US3受け入れシナリオ1〜2: 編集確定で表示変更＋完了状態維持、空文字確定で元の名前維持）in `test/pages/home_page_test.dart` — **失敗を確認**

### Implementation for User Story 3

- [ ] T020 [US3] コントローラにrenameを実装 in `lib/controllers/todo_list_controller.dart`
- [ ] T021 [US3] 編集UI（タスクタップまたは編集ボタン→ダイアログで名前変更）を実装 in `lib/pages/home_page.dart`
- [ ] T022 [US3] 検証ゲート: analyze/test クリーン、quickstart.md「US3」手動シナリオ実施

**Checkpoint**: ブランチ `feat/us3-edit-title` からPR → レビュー → マージ

---

## Phase 6: User Story 4 - 期限（日付）の設定 (Priority: P4)

**Goal**: 期限の設定・変更・解除と期限切れ未完了タスクの強調表示（spec US4、FR-008/009）。期限当日は期限切れ扱いしない

**Independent Test**: quickstart.md「US4」— 期限の設定/変更/解除、昨日期限の未完了のみ強調、完了で強調解除

### Tests for User Story 4（憲法II: 必須・実装より先）⚠️

- [ ] T023 [P] [US4] Taskモデルに`isOverdue`のテストを追加（昨日=切れ、今日=切れない、明日=切れない、完了済みは常に切れない、期限なしは切れない。**固定時刻を渡して判定**）in `test/models/task_test.dart` — **失敗を確認**
- [ ] T024 [P] [US4] コントローラの期限テストを追加（setDueDate/変更/解除（null）、保存される、**コンストラクタ注入の`now`関数**で期限切れ一覧が決定的に判定できる）in `test/controllers/todo_list_controller_test.dart` — **失敗を確認**
- [ ] T025 [P] [US4] 期限のウィジェットテストを追加（spec US4受け入れシナリオ1〜4: 期限日表示、変更/解除の反映、期限切れ強調は未完了のみ。テストでは固定時刻を注入）in `test/pages/home_page_test.dart` — **失敗を確認**

### Implementation for User Story 4

- [ ] T026 [US4] Taskモデルに`isOverdue(DateTime today)`を実装（日単位比較）in `lib/models/task.dart`
- [ ] T027 [US4] コントローラに`now`関数の注入（デフォルト`DateTime.now`）とsetDueDateを実装 in `lib/controllers/todo_list_controller.dart`
- [ ] T028 [US4] 期限UI（日付ピッカーで設定/変更/解除、一覧での期限日表示、期限切れ未完了の強調表示）を実装 in `lib/pages/home_page.dart`
- [ ] T029 [US4] 検証ゲート: analyze/test クリーン、quickstart.md「US4」手動シナリオ実施

**Checkpoint**: ブランチ `feat/us4-due-date` からPR → レビュー → マージ。全ストーリー完成

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: 仕上げとspec全体の検収

- [ ] T030 [P] タスク100件での動作テストを追加（コントローラに100件投入して操作が正しく完了する = SC-004の自動検証）in `test/controllers/todo_list_controller_test.dart`
- [ ] T031 [P] `README.md` をこのアプリの説明に更新（何のアプリか、起動方法、SDD練習リポジトリである旨、specs/へのリンク）
- [ ] T032 quickstart.md「4. データ破損時の回復」の手動検証（DevToolsでlocalStorage破壊→空一覧で起動 = FR-011）と、spec Success Criteria SC-001〜005の最終確認
- [ ] T033 検証ゲート: analyze/test クリーン → ブランチ `chore/polish` からPR → レビュー → マージ

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 依存なし。即開始可能
- **Foundational (Phase 2)**: Phase 1完了後。**全ユーザーストーリーをブロック**
- **User Stories (Phase 3〜6)**: Phase 2完了後。優先度順（P1→P2→P3→P4）に直列で進める
  - US2〜US4はいずれも `home_page.dart`・`todo_list_controller.dart` に追記するため、並行実施せずPR単位で直列にする（コンフリクト回避＋レビュー単位の維持）
- **Polish (Phase 7)**: 全ストーリー完了後

### Story Dependencies

- **US1 (P1)**: Foundationalのみに依存。単体でMVP
- **US2 (P2)**: US1のコントローラ・画面に追記（表示絞り込みのみ、US1機能に変更なし）
- **US3 (P3)**: US1に追記。US2とは独立にテスト可能
- **US4 (P4)**: US1に追記＋Taskモデル拡張。US2/US3とは独立にテスト可能

### Within Each User Story

- テストは必須（憲法II）。**先に書いて失敗を確認してから実装**
- モデル → コントローラ → UI の順
- 検証ゲート（analyze/test/quickstart）を通ってからPR

### Parallel Opportunities

- Phase 2: T003とT005（テスト作成）は並列可。実装T004→T006は順次
- 各ストーリー内: テスト作成タスク（例: T007とT008）は別ファイルのため並列可
- Phase 7: T030とT031は並列可
- **フェーズ間の並列はなし**（1人＋1エージェントでPRを直列に回すため）

---

## Implementation Strategy

### MVP First（US1のみ = 最初のリリース可能状態）

1. Phase 1 + Phase 2 + Phase 3（US1）を `feat/us1-basic-tasks` ブランチで実装
2. PR #1 を作成 → **人間レビュー** → マージ。この時点で使えるTodoアプリが完成
3. 以降 US2 → US3 → US4 を1ストーリー=1PRで積み上げ、各PRでレビュー

### PR運用（憲法III/IV）

- mainへの直接pushはしない（実装フェーズ以降）
- 各PRの説明にspec該当ストーリーとtasks.mdのタスクIDを記載
- レビューで仕様の曖昧さが見つかったら、実装修正ではなくspec/planの更新に戻る（憲法I）

### 想定PR構成

| PR | ブランチ | 含むタスク |
|----|---------|-----------|
| #1 | `feat/us1-basic-tasks` | T001〜T012（Setup＋Foundational＋US1） |
| #2 | `feat/us2-filter` | T013〜T017 |
| #3 | `feat/us3-edit-title` | T018〜T022 |
| #4 | `feat/us4-due-date` | T023〜T029 |
| #5 | `chore/polish` | T030〜T033 |
