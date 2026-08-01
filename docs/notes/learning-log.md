# 学びログ（todo-app SDD練習）

> 形式: AIとの開発セッションでの学びをAIがダイジェスト化したもの＋自分の言葉での追記。
> 「✍️ 自分の言葉で」欄は自分で埋める（埋めてこそアウトプット練習になる）。
> 期間: 2026-07-16〜 ／ 対象: PR #1〜#3 とその周辺の会話

---

## 軸1: 仕様駆動開発（SDD）

### SDDの全体構造

- フローは 憲法 → spec → plan → tasks → implement。**各段階の出口に人間レビュー**があり、承認済みの前段が次段の採点基準になる（specレビューがplanの物差しに、planレビューが実装PRの物差しになる連鎖）
- SDDの肝は文書が先にあることではなく、**文書・テスト・レビュー・IDが互いに検証し合うループ**:
  - **トレーサビリティ**: US1→FR-002→T007→テスト→実装 とIDで数珠つなぎ。根無し草のコードを検出できる
  - **判断理由の記録**: research.mdは決定だけでなく「却下した代替案と理由」を残す。AIは経緯を知らないので、文書がないと既決事項を蒸し返す
  - **driftの作法**: 仕様と実装がズレたら、コードを黙って直すのではなく**仕様側の改訂を先に通す**（憲法I）
- ✍️ 自分の言葉で:

### 契約（contract）

- 契約=「こう入力したらこう振る舞う」という**2者間の文書化された約束**。破ったかを客観判定できる（→契約テスト）
- このアプリの契約相手は「今日のアプリ」と「将来のアプリ」。storage-schema.mdが保存形式をversion付きで固定し、アプリを更新しても過去データが読める保証にする
- 契約が事前にmainにコミットされているから、実装PRのレビューは「合意済み文書との**答え合わせ**」になる
- ✍️ 自分の言葉で:

### Assumptions（前提）

- specで「明言されなかった細部をこう決めておく」と暗黙の決定を明文化するセクション。例: 削除は確認なし・同名重複OK・期限は日付のみ
- **技術知識ゼロで判断できるレビュアーの専管事項**。「この前提、自分の使い方と合ってる?」だけ問えばいい。実装後に直すと一番高くつく箇所
- ✍️ 自分の言葉で:

### どのファイルに何を書くか

- 各ファイルは「答える問い」が違う: spec=何を/なぜ、plan=どの技術で、research=なぜその技術か、data-model=データの意味、contracts=約束の形式、quickstart=どう確かめるか
- 同じ事実（例:「期限は日付のみ」）が spec / data-model / contract に**高度を変えて**現れるのは正常。重複ではなく屈折
- ✍️ 自分の言葉で:

### レビューの技法

- **深さを変える**: テスト=精読 / 実装=軽い通読 / 設定=一瞥。力の抜き方がレビュー技術
- **テストから読む**: テストはspecの受け入れシナリオの写しなので、コードが読めなくても照合レビューが成立する
- **質問も立派なレビュー**: 「この行何?」に実装者が答えられない箇所はだいたい修正すべき箇所
- **実機で触る**: headless検証が見落とした初回表示崩れ（PR #2のフィルタバー）を実機レビューが発見した。「触らないと出ない感想」が人間レビューの価値
- 説明と現物の食い違いに突っ込む（例: 「lockの差分はshared_preferencesだけ」への指摘）
- ✍️ 自分の言葉で:

---

## 軸2: Dart / Flutter

### pubspec.yaml と pubspec.lock

- yaml=人間が書く定義書（直接依存と許容バージョン範囲）、lock=機械が書く解決結果の記録。Node.jsのpackage.json / package-lock.jsonと同型
- **推移的依存**: 1つ入れると、それが要求する依存が連鎖で入る（shared_preferences 1つ→17パッケージ）。管理責任を持つのは直接依存だけ
- 確認コマンド: `flutter pub deps --style=compact`
- ✍️ 自分の言葉で:

### ChangeNotifierの通知の仕組み

- 正体は「コールバック関数のリストを持ち、notifyListeners()で全部呼ぶ」だけのObserverパターン
- 配線: View側の`ListenableBuilder`が`addListener`（購読登録）→ ViewModelの`notifyListeners()`（発火）→ builder再実行 → 最新状態で設計図を作り直し、Flutterが差分だけ描画
- **単方向データフロー**: 行き（操作）は`controller.add()`の直接呼び出し、帰り（変更通知）だけがObserver。main.dartは組み立て（Composition Root）のみで送受信に関与しない
- ✍️ 自分の言葉で:

### StatefulWidget と状態の寿命

- ウィジェットは不変の設計図で毎回作り直される。**再構築を生き残ってほしいデータの置き場**がStateオブジェクト
- HomePageがStatefulなのはsetStateのためではなく、`TextEditingController`の**寿命管理**（誕生時に生成・dispose()で片付け）のため
- PR #3の学び: ダイアログを閉じるアニメーション中に破棄済みcontrollerを参照するバグをテストが検出 → 「自分のリソースは自分のStateで管理する」形（_EditTaskDialogをStatefulWidget化）に修正
- **状態の3層**: 一時UI状態（ウィジェット内State）/ アプリ状態（ViewModel）/ 永続データ（Repository）。「これは誰と同じ寿命?」で置き場所が決まる
- Jetpack Compose対応: StatefulWidget+State ≈ `remember { mutableStateOf }`、rebuild ≈ recomposition、dispose ≈ `DisposableEffect`、ListenableBuilder購読 ≈ `collectAsState()`。**状態の置き場所と寿命という原理はフレームワーク横断で共通**
- ✍️ 自分の言葉で:

### Flutter webの特性

- 描画はcanvas（DOMにウィジェットは現れない）。ブラウザ自動操作にはセマンティクスDOMの有効化が必要
- 日本語フォントは遅延ダウンロードされ、初回描画の文字幅計測がズレることがある（フィルタバー折り返しバグの原因）。対策: フォント計測に依存しないレイアウト（固定幅ラベル）
- ✍️ 自分の言葉で:

---

## 軸3: アーキテクチャ

### このアプリの構造 = MVVM + Repository

- 対応: models/=Model、services/=Repository（データ層）、controllers/=ViewModel、pages/=View
- **ViewModel（todo_list_controller.dart）は画面の頭脳だが見た目を一切知らない**。importに`material.dart`がないのが証拠。だからUIなしでユニットテストできる
- **Repositoryパターン**: 保存先という技術詳細を1ファイルに隔離。差し替え時の変更範囲を閉じ込める
- ViewModelに`showDialog`や`Colors`が現れたら層の汚染サイン（レビュー観点）
- ✍️ 自分の言葉で:

### federated plugin（Flutterプラグインの構造）

- shared_preferences本体（Facade）→ platform_interface（抽象契約）→ OS別実装（Adapter/Strategy）という構成
- アプリ内のRepositoryパターンと同じ**依存性逆転**が、エコシステムレベルでも繰り返されている
- ✍️ 自分の言葉で:

### ChangeNotifier vs Riverpod

- ChangeNotifier=状態の入れ物だけ（SDK内蔵・依存ゼロ・配線は手動）。Riverpod=入れ物＋配り方＋組み立て（ref.watchでバケツリレー消滅、自動破棄、テストはoverridesで差し替え）
- 判断基準: バケツリレーが2〜3段を超え状態同士の依存が絡んだら移行を検討。1画面のこのアプリは手動配線が総コスト最小（憲法V）
- 計画: 習得後に別ブランチでRiverpod書き換え演習（テストが安全ネットになる体験）
- ✍️ 自分の言葉で:

---

## 軸4: プロセスでの出来事メモ

- PR #1: 基盤+US1。レビュー分割ガイド（深さ別・時間目安つき）が有効だった
- PR #2: フィルタ。**実機レビューで初回表示バグ発見**→指摘→原因究明→修正→PR記録→再確認のサイクルが一周
- PR #3: 編集ダイアログ。**テストがcontroller寿命バグを実行前に検出**（TDDの効果の実物）
- GitHubの仕様: PR作者は自分のPRをApproveできない（マージは可能）。PRの行コメントはAIがgh経由で読める（ただし通知はないので「コメント付けた」と一言伝える運用）
- ✍️ 自分の言葉で:
