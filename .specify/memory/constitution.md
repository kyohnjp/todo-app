<!--
Sync Impact Report
- Version change: (template) → 1.0.0
- Modified principles: 初回制定のため全principleを新規定義
  - I. 仕様が唯一の正（Spec as Single Source of Truth）
  - II. テスト必須（NON-NEGOTIABLE）
  - III. 小さな単位で作り、都度レビュー
  - IV. 人間＝意図とレビュー、AI＝実装
  - V. シンプルさ（過剰設計の禁止）
- Added sections: 技術スタック制約 / 開発ワークフロー
- Removed sections: なし
- Templates:
  - ✅ .specify/templates/tasks-template.md — 「Tests are OPTIONAL」をPrinciple IIに合わせて必須に更新
  - ✅ .specify/templates/plan-template.md — Constitution Checkゲートは汎用のまま整合（変更不要）
  - ✅ .specify/templates/spec-template.md — User Scenarios & Testing必須セクションと整合（変更不要）
  - ✅ .claude/skills/speckit-* — エージェント固有の古い参照なし（変更不要）
- Follow-up TODOs: なし
-->

# todo-app Constitution

Flutter製 Todo アプリを題材に、仕様駆動開発（SDD）／AI駆動開発の「型」を習得するための
練習プロジェクトの憲法。学びの主眼は **「レビュー側に立つ」訓練** にある。

## Core Principles

### I. 仕様が唯一の正（Spec as Single Source of Truth）

- すべての実装は `specs/[feature]/` 配下の spec.md → plan.md → tasks.md に遡れなければ
  ならない（MUST）。対応する仕様のないコード変更は行わない。
- バグや迷いはまず「実装ミス」ではなく「仕様の曖昧さ」として扱う（MUST）。詰まったら
  コードをいじる前に仕様に戻り、仕様を直してから実装を直す。
- 仕様と実装がズレた場合（spec drift）、仕様側を正として実装を追従させるか、意図的な変更
  なら仕様を先に更新する（MUST）。

根拠: SDDの核は「仕様を single source of truth にする」こと。driftとハルシネーションは
避けられない前提で、仕様への回帰を習慣化する。

### II. テスト必須（NON-NEGOTIABLE）

- すべての機能・タスクには自動テストを伴う（MUST）。`flutter test` が通らないタスクは
  完了とみなさない。
- `flutter analyze` がクリーン（エラー・警告なし）であることをタスク完了の条件とする
  （MUST）。
- テストは仕様の受け入れシナリオ（User Scenarios & Testing）から導出する（SHOULD）。
  仕様にないふるまいをテストで固定しない。

根拠: AI実装では spec drift とハルシネーションが本質的に避けられないため、テスト＋人間の
レビューが品質担保の要になる。

### III. 小さな単位で作り、都度レビュー

- タスクは1つずつ進め、1単位（コミット／PR相当）を小さく保つ（MUST）。大きなタスクは
  実装前に分割する。
- 各単位の完了時に人間のレビューを経てから次に進む（MUST）。複数タスクをまとめて
  レビューに出さない。
- 一度にAIへ渡すコンテキストを肥大させない（SHOULD）。1タスクに必要な情報だけを渡す。

根拠: AIエージェント時代のボトルネックは実装ではなくレビュー。単位が小さいほどレビューが
成立し、暴走の検知が早くなる。

### IV. 人間＝意図とレビュー、AI＝実装

- 人間の役割は「意図の定義（specify/clarify）」と「レビュー」、AIの役割は「実装」とする
  （MUST）。この分担を各段階で崩さない。
- 人間のレビューを経ていない変更を main に取り込まない（MUST）。
- 指示は5W1Hを明確にし、曖昧な指示でAIに実装させない（MUST）。曖昧さに気づいたら
  clarify に戻す。

根拠: このプロジェクトの学習目標そのもの。「レビュー側に立つ」訓練を仕組みとして強制する。

### V. シンプルさ（過剰設計の禁止）

- 題材は練習用の Todo アプリである。仕様が要求しない抽象化・レイヤー・依存を導入しない
  （MUST、YAGNI）。
- 仕様を満たす最も単純な構成を既定とし、複雑な設計を選ぶ場合は plan.md の
  Complexity Tracking で正当化する（MUST）。
- セットアップやツール整備は time-box する（SHOULD）。環境攻略を目的化しない。

根拠: 個人開発の典型的失敗（過剰設計・セットアップの目的化）を憲法で予防する。

## 技術スタック制約

- フレームワーク: Flutter（ターゲットは web）。言語は Dart。実行は
  `flutter run -d chrome` を基本とする。
- 静的解析: リポジトリの `analysis_options.yaml` に従い、`flutter analyze` を通す。
- 状態管理・永続化: 仕様を満たす最小構成を選ぶ。バックエンドや外部サービスは仕様が明示的に
  要求しない限り導入しない。
- テスト: `flutter_test` によるユニット／ウィジェットテストを基本とする。

## 開発ワークフロー

- Spec Kit の標準フローに従う:
  `/speckit-specify` →（必要に応じ `/speckit-clarify`）→ `/speckit-plan` →
  `/speckit-tasks` → `/speckit-implement`。
- plan.md の Constitution Check ゲートで本憲法との適合を確認してから設計・実装に進む。
- 各タスクの完了条件: 実装 → `flutter test` と `flutter analyze` が通る → コミット →
  人間のレビュー。
- レビューで仕様の曖昧さが見つかった場合は、実装の手直しではなく spec/plan の更新から
  やり直す（Principle I）。

## Governance

- 本憲法はプロジェクト内の他のあらゆる慣行・テンプレートに優先する。
- 改定は `/speckit-constitution` を通じて行い、Sync Impact Report を残す。バージョンは
  semantic versioning に従う（MAJOR: 原則の削除・再定義、MINOR: 原則・セクションの追加や
  実質的拡張、PATCH: 文言の明確化）。
- すべての plan は Constitution Check で本憲法への適合を検証し、違反する複雑さは
  Complexity Tracking で正当化されない限り認めない。
- レビュー時（PR相当の単位ごと）に Principle II〜IV の遵守を確認する。

**Version**: 1.0.0 | **Ratified**: 2026-07-16 | **Last Amended**: 2026-07-16
