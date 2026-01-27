# NLH Flip-Out UIデザイン刷新計画

## 概要

スマホ向け縦長UIで、オンラインカジノアプリ風の高級感あるポーカーテーブルUIを実装する。

## デザインコンセプト

**トーン**: Luxury Casino / Art Deco風の高級感
**差別化要素**: 縦長楕円テーブルを中心に、プレイヤーが有機的に配置される没入感

## カラーパレット

```css
:root {
  /* フェルト（ダークグリーン） */
  --felt-dark: #0d4a2d;
  --felt-light: #1a5f3c;

  /* 木製レール（マホガニー） */
  --rail-dark: #3d1f1f;
  --rail-light: #5c2e2e;

  /* ゴールドアクセント */
  --gold-primary: #d4af37;
  --gold-light: #f4d58d;
  --gold-glow: rgba(212, 175, 55, 0.4);

  /* 背景 */
  --bg-dark: #0a0a0a;
  --bg-overlay: rgba(0, 0, 0, 0.6);

  /* テキスト */
  --text-primary: #ffffff;
  --text-secondary: rgba(255, 255, 255, 0.7);
}
```

## レイアウト構成

```
┌─────────────────────────────────────────┐
│                                         │
│     ┌─────┐           ┌─────┐          │  ← 上部プレイヤー（2人）
│     │ P1  │           │ P2  │          │
│     └─────┘           └─────┘          │
│                                         │
│   ┌───────────────────────────────┐    │
│   │                               │    │  ← ポーカーテーブル
│ P8│     ┌───────────────────┐    │P3  │     楕円形、フェルト
│   │     │  Community Cards  │    │    │     中央にコミュニティ
│   │     │   [  ] [  ] [  ]  │    │    │
│   │     │   [  ] [  ]       │    │    │
│   │     └───────────────────┘    │    │
│ P7│                               │P4  │
│   │        [River Squeeze]       │    │
│   └───────────────────────────────┘    │
│                                         │
│     ┌─────┐           ┌─────┐          │  ← 下部プレイヤー（2人）
│     │ P6  │           │ P5  │          │
│     └─────┘           └─────┘          │
│                                         │
├─────────────────────────────────────────┤
│         [  DEAL  ]        [⚙️]          │  ← 状態に応じて切り替え
│    or   [NEW HAND]        [⚙️]          │     (Showdown時のみNEW HAND)
└─────────────────────────────────────────┘
```

**ヘッダーなし**: タイトル表示は不要
**ボタン切り替え**:
- Ready〜RiverSqueeze: DEALボタンのみ
- Showdown: NEW HANDボタンのみ

## プレイヤー配置ロジック（人数別）

| 人数 | 配置 |
|-----|------|
| 2人 | 上中央、下中央 |
| 3人 | 上中央、下左、下右 |
| 4人 | 上左、上右、下左、下右 |
| 5人 | 上左、上右、右側面、下左、下右 |
| 6人 | 上左、上右、右側面、下左、下右、左側面 |
| 7人 | 上左、上中央、上右、右、下右、下左、左 |
| 8人 | 上左、上中央、上右、右上、右下、下右、下左、左 |

## 修正対象ファイル

### 1. `styles/main.css` - 全面書き換え

- ダークカジノテーマ適用
- CSS変数でカラーパレット定義
- 楕円形テーブル背景
- プレイヤー絶対配置

### 2. `styles/cards.css` - カードデザイン強化

- 高級感のあるカードデザイン
- ゴールドのハイライト効果
- 影とグラデーション強化

### 3. `index.html` - 構造変更

- ヘッダー削除
- テーブルコンテナ追加
- プレイヤー位置クラス対応
- DEALとNEW HANDボタンを状態で切り替え

### 4. `src/ui/render.ts` - レンダリング変更

- プレイヤー配置ロジック追加
- 人数に応じた位置計算
- ボタン表示切り替えロジック（DEAL/NEW HAND排他）

## CSS実装詳細

### ポーカーテーブル

```css
.poker-table {
  position: relative;
  width: 100%;
  max-width: 380px;
  aspect-ratio: 3/4;
  margin: 0 auto;
  background:
    radial-gradient(ellipse 90% 70% at center,
      var(--felt-light) 0%,
      var(--felt-dark) 100%);
  border-radius: 50% / 40%;
  box-shadow:
    inset 0 0 60px rgba(0, 0, 0, 0.5),
    0 0 0 12px var(--rail-dark),
    0 0 0 16px var(--rail-light),
    0 8px 32px rgba(0, 0, 0, 0.8);
}
```

### プレイヤーカード配置

```css
.player-seat {
  position: absolute;
  transform: translate(-50%, -50%);
}

/* 2人用 */
.players-2 .seat-0 { top: 5%; left: 50%; }
.players-2 .seat-1 { top: 95%; left: 50%; }

/* 8人用 */
.players-8 .seat-0 { top: 5%; left: 25%; }
.players-8 .seat-1 { top: 5%; left: 50%; }
.players-8 .seat-2 { top: 5%; left: 75%; }
/* ... 続く */
```

### コントロールボタン

```css
.btn-deal {
  background: linear-gradient(180deg,
    var(--gold-light) 0%,
    var(--gold-primary) 50%,
    #b8962e 100%);
  color: #1a1a1a;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  box-shadow:
    0 4px 0 #8b7028,
    0 6px 20px var(--gold-glow);
}
```

## 検証方法

### 手動検証チェックリスト

- [ ] テーブルが縦長楕円で表示される
- [ ] 2〜8人の各人数でプレイヤーが正しく配置される
- [ ] コミュニティカードがテーブル中央に表示
- [ ] ゴールドアクセントが適切に適用
- [ ] スマホ縦画面で収まる
- [ ] タッチ操作でスクイーズが動作
- [ ] 勝者ハイライトがゴールドで目立つ

### ローカル確認

```bash
npm run dev
# http://localhost:5173/flipout/ でアクセス
# Chrome DevToolsでモバイルビューを確認
```
