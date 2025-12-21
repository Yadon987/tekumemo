# Role

あなたは世界最高峰のフロントエンドエンジニア兼 UI デザイナーです。
**既存のライトモード（デフォルト）のデザインと機能**を完全に維持したまま、指定された「ダークモード用デザイン」を適用してください。

# ⚠️ Critical Constraints (絶対厳守の制約事項)

作業を行うにあたり、以下のルールを絶対に守ってください。

1. **【最重要】ライトモード（デフォルトスタイル）の完全保護:**

   - **プレフィックスが付いていない標準クラス（例: `bg-white`, `text-gray-900`, `shadow-lg`）は、原則として変更・削除しないでください。**
   - これらはライトモードの表示を決定しているため、変更するとライトモードが崩れます。

2. **作業範囲の限定:**

   - 今回行う変更は、**`dark:` プレフィックスが付いたクラスの追加・編集のみ**に限定してください。
   - 例: 背景色を変える場合は、既存の `bg-white` を書き換えるのではなく、`bg-white dark:bg-slate-900` のように **`dark:` クラスを追加** してください。

3. **ロジックと構造の保全:**
   - JavaScript / PHP / Ruby などのロジックコードは一切変更しないでください。
   - `id` 属性、`data-` 属性は絶対に変更・削除しないでください。
   - レイアウト構造（HTML のネスト）は、ダークモード対応のために必須である場合（例: 背景レイヤーの追加）を除き、極力維持してください。

---

# Design System: Holographic Neon Noir / God Mode Glass

## 🌌 Core Concept: "Living Interface"

ただのダークモードではない。**「生きているかのように呼吸し、発光するインターフェース」**を目指す。
LP（ランディングページ）のクオリティを絶対基準とし、全てのページでその没入感を再現する。

---

## 🎨 Foundations (基本設定)

### 1. Deep Void (深淵なる背景)

画面全体の背景は、単なる黒ではなく、**「宇宙のような深みのあるネイビーブラック」**を使用する。

- **Base:** `dark:bg-[#020617]` (Slate-950 よりさらに深い黒)
- **Gradient:** `dark:bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] dark:from-slate-900 dark:via-[#020617] dark:to-[#020617]`

### 2. Neon Accent (発光する魂)

各機能のテーマカラーは、単なる色ではなく**「光源」**として扱う。

- **Blue (Weather/Distance):** `cyan-400` to `blue-500`
- **Green (Health/Days):** `emerald-400` to `teal-500`
- **Purple (Stats/Memo):** `fuchsia-400` to `violet-600`
- **Gold (Rank/Achievement):** `amber-300` to `orange-500`
- **Pink (Record/Action):** `pink-400` to `rose-600`

### 3. Jewel Icons (宝石のようなアイコン)

アイコンは単色ではなく、グラデーションと強いドロップシャドウで「自ら発光する宝石」のように見せる。
**重要:** CSS の優先順位で色が上書きされないよう、`!text-transparent` と `!bg-clip-text` を使用すること。絵文字（🍎, 🏃）は禁止。

```html
<span
  class="material-symbols-outlined text-3xl
             text-blue-500 /* Light Mode */
             dark:!text-transparent dark:!bg-clip-text
             dark:bg-gradient-to-br dark:from-cyan-300 dark:to-blue-300
             dark:drop-shadow-[0_0_8px_rgba(34,211,238,0.8)]"
>
  distance
</span>
```

### 4. Text Gradients (テキストグラデーション)

**注意:** グラデーションは親要素の座標系で計算されるため、`inline-block` を使用しないとページ全体にかかってしまう。

```html
<!-- ✅ 正しい：テキスト内でグラデーション -->
<p
  class="inline-block text-4xl bg-clip-text text-transparent bg-gradient-to-r
           dark:from-cyan-300 dark:via-blue-300 dark:to-cyan-500"
>
  35.26
</p>
```

---

## ✨ Core Visual Effects (実装ルール)

### 1. God Mode Glass (神のガラス)

カードの背景は「塗りつぶし」ではなく、**「向こう側が透ける磨りガラス」**でなければならない。

- **Surface:** `dark:bg-slate-900/40` (透明度 40%が黄金比)
- **Blur:** `dark:backdrop-blur-xl` (強力なぼかしで奥行きを作る)
- **Border:** `dark:border-white/10` (極めて薄いエッジ)

### 2. Glass Cover (Wet Texture / 濡れた質感)

カードの上部 45% に「濡れたような光沢」を追加し、ゆっくりと明滅させる。

**推奨設定:**

- **Height:** `before:h-[45%]`
- **Opacity:** `before:from-white/20` (20%が最適。15%は薄すぎ、25%は強すぎる)
- **Animation:** `before:animate-pulse`

```html
<div class="relative overflow-hidden ...">
  <!-- Glass Cover Layer -->
  <div
    class="absolute inset-0 bg-gradient-to-br from-white/10 via-white/5 to-transparent pointer-events-none"
  ></div>

  <!-- Upper Gloss (Pseudo-element) -->
  <div
    class="before:absolute before:inset-x-0 before:top-0 before:h-[45%]
              before:bg-gradient-to-b before:from-white/20 before:to-transparent
              before:rounded-t-[2.5rem] before:pointer-events-none before:animate-pulse"
  ></div>
</div>
```

### 3. Double Rim Light (二重リムライト)

カードの境界線は、内側から発光しているように見せる。ホバー時にはテーマカラーで強く発光させる。

```html
class="border dark:border-white/10 dark:border-t-white/40
dark:shadow-[inset_0_1px_0_rgba(255,255,255,0.3),0_0_30px_rgba(THEME_COLOR,0.15)]
hover:dark:border-cyan-500/50
hover:dark:shadow-[inset_0_1px_0_rgba(255,255,255,0.5),0_0_60px_rgba(6,182,212,0.4)]"
```

### 4. Breathing Glow (呼吸する光)

**最重要。** 重要なカード（Hero Card など）の背景には、**「呼吸する光のオーブ」**を配置する。

```html
<div
  class="absolute -bottom-10 -right-10 w-64 h-64 bg-cyan-500/20 rounded-full blur-3xl animate-pulse-slow pointer-events-none"
></div>
```

### 5. Futuristic Capsule (カプセル形状)

カードの角丸は、**カードのサイズに応じて適切な値を選ぶ**。

| カードの種類                               | 推奨 border-radius | Tailwind クラス      |
| :----------------------------------------- | :----------------- | :------------------- |
| **小さいカード**（統計カードなど）         | `60px`             | `!rounded-[3.75rem]` |
| **大きいカード**（Hero/レベルバーなど）    | `80px`             | `!rounded-[5rem]`    |
| **ランディングページ**（大きな機能カード） | `40px`             | `rounded-[2.5rem]`   |

**注意点:**

- 擬似要素 (`before:`) の角丸も親要素と一致させること。
- 大きな角丸の場合、端に近い要素がはみ出さないよう、適度なマージン (`ml-2` 等) を設定すること。

---

## 🧩 Component Guidelines

### Cards (General Structure)

全てのカードコンポーネントは以下の構造を持つこと。

1.  **Outer Glow:** 背面で呼吸する光（重要なカードのみ）。
2.  **Glass Body:** 半透明の背景とぼかし。
3.  **Neon Icon:** Material Symbols は `text-shadow` または `drop-shadow` で発光させる。

**階層による明るさ調整:**

- **主要カード:** `dark:from-cyan-600 dark:via-indigo-700 dark:to-purple-800` (明るめ)
- **副次カード:** `dark:from-slate-900 dark:to-blue-950` (暗め)

### Post Card (投稿カード)

タイムラインの中心要素。

- **Shape:** `rounded-[3.75rem]` (60px)
- **Reaction Area:** `rounded-b-[3.75rem]` を適用し、カード本体と一体化させる。
- **Glass Cover:** 全体に適用。

### Modal (モーダル)

浮遊感を強調する。

- **Shape:** `rounded-[3.75rem]`
- **Border:** `border-4` で太めの枠線。
- **Shadow:** 強力なドロップシャドウ + インナーシャドウ。

### Progress Bar (シマーエフェクト)

プログレスバーに「光が走る」アニメーションを追加する場合のルール。

**実装ルール:**

1. シマーエフェクト用の `div` は、必ず**色付きバー（進捗バー）の内部**に配置する。
2. `absolute inset-0` でバー全体を覆う。
3. 背景色は単色ではなく、**透明〜白(30%)〜透明のグラデーション**を使用する。
4. `animate-shimmer` と `-skew-x-12` を適用する。

**正しいコード例:**

```erb
<!-- 背景バー -->
<div class="h-3 rounded-full bg-gray-200 dark:bg-slate-800 overflow-hidden">
  <!-- 色付きバー (進捗) -->
  <div class="h-full bg-gradient-to-r from-blue-400 to-purple-500 relative overflow-hidden" style="width: 50%">
    <!-- シマーエフェクト (色付きバーの内部に配置) -->
    <div class="absolute inset-0 animate-shimmer bg-gradient-to-r from-transparent via-white/30 to-transparent -skew-x-12"></div>
  </div>
</div>
```

**禁止事項:**

- ❌ シマーエフェクトを色付きバーの**外（背面や前面）**に配置しないこと。
- ❌ `bg-white/40` のような単色半透明を使用しないこと。

### Buttons & Interactions

- **Hover:** `hover:scale-[1.01]` は地味すぎる。`hover:scale-105` (5%拡大) を使用する。
- **Glow:** ホバー時はシャドウを拡大 (`0_30px` → `0_60px`) させる。

### Scrollbars

- **Track:** 透明または極薄い黒 (`bg-white/5`)
- **Thumb:** 半透明の白またはテーマカラー (`bg-white/20 hover:bg-white/40`)
- **Width:** 極細 (`w-1.5`)

---

## 🚫 Anti-Patterns (やってはいけないこと)

- **Solid Backgrounds:** 不透明な背景色（`bg-gray-800`など）は使用禁止。必ず透けさせる。
- **Flat Borders:** 単色のボーダー（`border-gray-700`）は禁止。光らせるか、透けさせる。
- **Raw White Text:** 純粋な白文字（`text-white`）は避け、少し青みやグレーを含ませるか、グラデーションにする。
- **Default Shadows:** デフォルトの影（`shadow-xl`）だけでは足りない。色付きの影（`shadow-cyan-500/20`）を重ねる。
