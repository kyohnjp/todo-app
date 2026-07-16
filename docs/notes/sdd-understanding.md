# 仕様駆動開発（SDD）／AI駆動開発の理解メモ

作成: 2026-07-15 ／ 出典: deep-research（多源・敵対的検証つき。確度は各項に明記）
用途: この練習アプリ（todo-app）で「AI駆動開発／仕様駆動開発の型」を習得するための理解の地図。自分の言葉でのアウトプット（技術記事の種）の下敷き。

> ⚠️ この分野は2025〜2026年の新語彙。コマンド名やツール仕様は変わりやすい。断定できない箇所は明記した。ツールの正確な仕様は必ず公式で確認すること。

---

## 一言の地図

**AI駆動開発**（＝開発の全工程にAIを組み込む"傘"）の下に、両極の手法として **vibe coding**（対話で雰囲気を伝え直感で試行錯誤）と **仕様駆動開発SDD**（仕様を"唯一の正"にしてAIに作らせる）がある。さらに外側に、エージェントの実行環境そのものを設計する **ハーネスエンジニアリング**。学ぶのは真ん中の **SDD**。

---

## 1. 用語の関係

- **vibe coding**：仕様を書かず対話で即興。速いが「一見正しいが動かない／使い捨て」コードになりやすい（Karpathy起源）。
- **SDD（Spec-Driven Development）**：流れを反転（コード先→文書後 ではなく **仕様が先で "single source of truth"**）。AIはその仕様に沿って生成・テスト・検証。
- **ハーネスエンジニアリング**：モデルを実用エージェントに変える"実行環境"（ループ・ツール呼び出し・コンテキスト管理・エラー処理）を設計する層。`Agent = Model + Harness`（Mitchell Hashimoto, 2026-02）。LangChain/MCP/RAGはハーネスの部品。＝**ツールを作る側の話。今は不要**。
- ⚠️ 確度：「AI駆動開発＝傘」の階層や"4スタイル進化段階"は主にブログ発の整理。本流は「vibe vs SDD」の対比。地図として使うのは可、絶対的分類ではない。
- ⚠️ 反証済み：「CLAUDE.mdを書く行為＝ハーネスエンジニアリング」／「Context・Agentic・Harnessの3層整理」は検証で反証（鵜呑みにしない）。

## 2. SDDの標準ワークフロー

**spec（要件・何を/なぜ）→ plan（設計・どう）→ tasks（分解）→ implement（実装）** の4段階。
- **一発生成でなく"多段階リファインメント"**。
- 役割は毎段階 **人間＝意図の定義＋レビュー／AI＝実装**。
- vibe との差：「**曖昧さのない指示**」「human-in-the-loop」「要件分析・設計・制約を先に入れる」。ただしウォーターフォールではなく**短いフィードバックループ**。

## 3. ツール

- **GitHub Spec Kit**が一次情報も最整備で個人開発の定番（本プロジェクトで採用）。
  - CLI: `uv tool install specify-cli` → `specify init <name> --integration claude`
  - コマンド（**インストール版0.12.16は ハイフン 表記・`.claude/skills/`に導入**）：
    `/speckit-constitution` `/speckit-specify` `/speckit-clarify` `/speckit-plan` `/speckit-analyze` `/speckit-tasks` `/speckit-taskstoissues` `/speckit-checklist` `/speckit-implement` `/speckit-converge`
- 他に cc-sdd / OpenSpec / Kiro(AWS) / Tessl 等。※**Kiroの詳細ワークフローは検証で確証が落ちた**ので鵜呑みにしない。

## 4. ディレクトリ構成（Spec Kit）

```
.specify/
├── memory/constitution.md      # 不変(immutable)の高レベル原則。全変更に適用
├── templates/                  # spec/plan/tasks のテンプレ
└── scripts/bash/
specs/[feature-name]/
├── spec.md   # 何を・なぜ
├── plan.md   # 設計・どう
├── tasks.md  # 分解
└── data-model.md / research.md / quickstart.md ...
```
- constitution＝**全体を貫く原則**（例：テスト必須・実行先・命名規約）。init時に生成、`/speckit-constitution`で内容を作る。

## 5. PR単位の実装とレビュー

- **spec drift（仕様と実装のズレ）とハルシネーションは"本質的に避けられない"**。だから**テスト＋人間のレビュー＋（できればCI）**で品質を担保するのが型の核。
- 実践者の金言：「**AIエージェント時代、ボトルネックは実装でなくレビューになる**」＝"レビュー側に立つ"訓練がこの練習の主眼。
- ⚠️ 「1PRの理想サイズ」等の具体値は確かなソースが乏しい＝**現場で自分の感覚を作る領域**。

## 6. 個人開発の失敗と、型を最短で得るコツ

- **指示が曖昧＝AIが暴走** → 5W1Hを明確化。
- **大タスクを小さく割り、1つずつ確認**（PR粒度を小さく）。
- **コンテキスト肥大を避ける**（一度に抱えさせない）。
- **過剰設計を避ける**（題材に対して重すぎる設計をしない）。
- **バグは"実装ミス"でなく"仕様の曖昧さ"として現れる** → 詰まったら仕様に戻る。

---

## この練習台への落とし込み

- 昨日の設計「原則＋spec/plan/tasks＋PR単位でAI実装→レビュー」は **SDDの正統形**。Spec Kit をそのまま採用してこれを踏む。
- **テスト必須をconstitutionに入れる**（drift/ハルシネーション対策の要）。
- 学びの主眼は「**レビュー側に立つ**」＝時代のボトルネックそのもの。
- セットアップ攻略が目的化しないよう time-box。

## 主な出典

- GitHub Spec Kit（公式）: https://github.com/github/spec-kit ／ 導入ブログ: https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/
- Thoughtworks（SDD 2025）: https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices
- Martin Fowler（SDD 3ツール／野心の3段階）: https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
- @IT（日本語SDD解説）: https://atmarkit.itmedia.co.jp/ait/articles/2510/07/news022.html
- 4スタイル整理（Zenn）: https://zenn.dev/kenimo49/articles/vibe-spec-harness-three-styles-map
- レビューがボトルネック（Qiita）: https://qiita.com/akira_papa_AI/items/a492e6ceb5c0790df5c4
