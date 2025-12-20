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

4. **オーバーライドの徹底:**

# Design System:# Holographic Neon Noir / God Mode Glass (Dark Mode System)

## 🌌 Core Concept: "Living Interface"

ただのダークモードではない。**「生きているかのように呼吸し、発光するインターフェース」**を目指す。
LP（ランディングページ）のクオリティを絶対基準とし、全てのページでその没入感を再現する。

---

## 🎨 Color Palette & Backgrounds

### 1. Deep Void (深淵なる背景)

画面全体の背景は、単なる黒ではなく、**「宇宙のような深みのあるネイビーブラック」**を使用する。

- **Base:** `dark:bg-[#020617]` (Slate-950 よりさらに深い黒)
- **Gradient:** `dark:bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] dark:from-slate-900 dark:via-[#020617] dark:to-[#020617]`

### 2. God Mode Glass (神のガラス)

カードの背景は「塗りつぶし」ではなく、**「向こう側が透ける磨りガラス」**でなければならない。

- **Surface:** `dark:bg-slate-900/40` (透明度 40%が黄金比)
- **Blur:** `dark:backdrop-blur-xl` (強力なぼかしで奥行きを作る)
- **Border:** `dark:border-white/10` (極めて薄いエッジ)

### 3. Neon Accent (発光する魂)

各機能のテーマカラーは、単なる色ではなく**「光源」**として扱う。

- **Blue (Weather/Distance):** `cyan-400` to `blue-500`
- **Green (Health/Days):** `emerald-400` to `teal-500`
- **Purple (Stats/Memo):** `fuchsia-400` to `violet-600`
- **Gold (Rank/Achievement):** `amber-300` to `orange-500`
- **Pink (Record/Action):** `pink-400` to `rose-600`

---

## ✨ Key Visual Effects (実装ルール)

### 1. Glass Cover (Wet Texture / 濡れた質感)

カードの上部 45% に「濡れたような光沢」を追加し、ゆっくりと明滅させることで、硬質なガラスではなく「有機的な液体ガラス」の質感を表現する。

```html
<!-- 親要素には relative overflow-hidden が必須 -->
<div class="relative overflow-hidden ...">
  <!-- Glass Cover Layer -->
  <div
    class="absolute inset-0 bg-gradient-to-br from-white/10 via-white/5 to-transparent pointer-events-none"
  ></div>

  <!-- Upper Gloss (Pseudo-element recommended) -->
  <div
    class="before:absolute before:inset-x-0 before:top-0 before:h-[45%]
              before:bg-gradient-to-b before:from-white/15 before:to-transparent
              before:rounded-t-[2.5rem] before:pointer-events-none before:animate-pulse"
  ></div>
  ...
</div>
```

### 2. Jewel Icons (宝石のようなアイコン)

アイコンは単色ではなく、グラデーションと強いドロップシャドウで「自ら発光する宝石」のように見せる。
**重要:** CSS の優先順位で色が上書きされないよう、`!text-transparent` と `!bg-clip-text` を使用すること。

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

### 3. Futuristic Capsule (カプセル形状)

カードの角丸は、**カードのサイズに応じて適切な値を選ぶ**ことが重要。

#### 📏 サイズ別の角丸設定

| カードの種類                               | 推奨 border-radius | Tailwind クラス      |
| ------------------------------------------ | ------------------ | -------------------- |
| **小さいカード**（統計カードなど）         | `60px`             | `!rounded-[3.75rem]` |
| **大きいカード**（Hero/レベルバーなど）    | `80px`             | `!rounded-[5rem]`    |
| **ランディングページ**（大きな機能カード） | `40px`             | `rounded-[2.5rem]`   |

**重要：** 小さいカードに `40px` を使うと「少し丸い」程度にしか見えず、カプセル感が出ない。統計ページのような小さいカードには **`60px`（3.75rem）以上** が必要。

#### ⚠️ 角丸適用時の必須事項

1.  **擬似要素の角丸も統一する**

    ```html
    before:!rounded-t-[3.75rem]
    <!-- 親と同じ値 -->
    ```

2.  **Breathing Glow（外側の光）も統一する**

    ```html
    <div class="... rounded-[3.75rem] blur-xl ...">
      <!-- カード本体と同じ -->
    </div>
    ```

3.  **`!important` を使用する**
    - `.crystal-card` のベーススタイルを上書きするため、`!rounded-[3.75rem]` のように `!` を付ける

---### 4. Double Rim Light (二重リムライト)

カードの境界線は、内側から発光しているように見せる。

```html
class="border dark:border-white/10 dark:border-t-white/40
dark:shadow-[inset_0_1px_0_rgba(255,255,255,0.3),0_0_30px_rgba(THEME_COLOR,0.15)]"
```

さらに、ホバー時にはテーマカラーで強く発光させる。

```html
class="hover:dark:border-cyan-500/50
hover:dark:shadow-[inset_0_1px_0_rgba(255,255,255,0.5),0_0_60px_rgba(6,182,212,0.4)]"
```

### 5. Breathing Glow (呼吸する光)

**最重要。** 重要なカード（Hero Card など）の背景には、**「呼吸する光のオーブ」**を配置する。
これにより、画面が静止画ではなく「生きている」と感じさせる。

```html
<!-- カード内の絶対配置で背面に置く -->
<div
  class="absolute -bottom-10 -right-10 w-64 h-64 bg-cyan-500/20 rounded-full blur-3xl animate-pulse-slow pointer-events-none"
></div>
```

_※ `animate-pulse-slow` は `tailwind.config.js` で定義が必要（3 秒〜4 秒周期のゆったりとした明滅）。_

---

## 🧩 Component Guidelines

### Cards (God Mode Card)

全てのカードコンポーネントは以下の構造を持つこと。

1.  **Outer Glow:** 背面で呼吸する光（重要なカードのみ）。
2.  **Glass Body:** 半透明の背景とぼかし。
3.  **Neon Icon:** Material Symbols は `text-shadow` または `drop-shadow` で発光させる。

### Icons

絵文字（🍎, 🏃）は禁止。必ず **Material Symbols** を使用し、テーマカラーで発光させる。

```html
<span
  class="material-symbols-outlined text-3xl
             text-cyan-500
             dark:!text-transparent dark:!bg-clip-text
             dark:bg-gradient-to-br dark:from-cyan-300 dark:to-blue-300
             dark:drop-shadow-[0_0_8px_rgba(34,211,238,0.8)]"
>
  directions_run
</span>
```

### Scrollbars

スクロールバーも世界観の一部である。

- **Track:** 透明または極薄い黒 (`bg-white/5`)
- **Thumb:** 半透明の白またはテーマカラー (`bg-white/20 hover:bg-white/40`)
- **Width:** 極細 (`w-1.5`)

---

## 🚫 Anti-Patterns (やってはいけないこと)

- **Solid Backgrounds:** 不透明な背景色（`bg-gray-800`など）は使用禁止。必ず透けさせる。
- **Flat Borders:** 単色のボーダー（`border-gray-700`）は禁止。光らせるか、透けさせる。
- **Raw White Text:** 純粋な白文字（`text-white`）は避け、少し青みやグレーを含ませるか、グラデーションにする。
- **Default Shadows:** デフォルトの影（`shadow-xl`）だけでは足りない。色付きの影（`shadow-cyan-500/20`）を重ねる。

### ⚠️ テキストグラデーションの落とし穴

**問題：** グラデーションが**ページ全体**に適用されてしまう

グラデーション（`bg-gradient-to-r`）は親要素の座標系で計算されるため、`<p>` タグがブロック要素の場合、画面左端から右端へのグラデーションになる。結果、左側のカードは明るく、右側のカードは暗くなってしまう。

**解決策：** `inline-block` を使う

```html
<!-- ❌ 間違い：ページ全体でグラデーション -->
<p
  class="text-4xl bg-clip-text text-transparent bg-gradient-to-r
           dark:from-cyan-300 dark:to-cyan-500"
>
  35.26
</p>

<!-- ✅ 正しい：テキスト内でグラデーション -->
<p
  class="inline-block text-4xl bg-clip-text text-transparent bg-gradient-to-r
           dark:from-cyan-300 dark:to-cyan-500"
>
  35.26
</p>
```

**推奨グラデーション：** 3 色で豊かに

```html
dark:from-cyan-300 dark:via-blue-300 dark:to-cyan-500 dark:from-purple-300
dark:via-fuchsia-300 dark:to-purple-500 dark:from-orange-300 dark:via-red-300
dark:to-orange-500
```

---

### ⚡ ホバーアニメーション

**問題：** `hover:scale-[1.01]` では地味すぎる

**解決策：** `hover:scale-105`（5%拡大）を使用

```html
class="... transition-all duration-300 hover:scale-105
hover:dark:shadow-[0_0_60px_rgba(...,0.3)] ..."
```

**効果：**

- カードが手前に飛び出してくるような派手なインタラクション
- シャドウの拡大（`0_30px` → `0_60px`）と組み合わせることで、より立体感が出る

---

### 📊 プログレスバーのシマーエフェクト

**問題：** シマーが色付きバーの範囲を超えて表示される

シマーエフェクトの親要素が「色付きバー」（幅が可変）の場合、アニメーションがその幅を基準に計算されるため、全体バーからはみ出して消える。

**解決策：** 色付きバーに `overflow-hidden` を追加

```html
<!-- ❌ 間違い -->
<div class="h-full bg-gradient-to-r ... rounded-full" style="width: 20%">
  <div class="animate-shimmer ..."></div>
</div>

<!-- ✅ 正しい -->
<div
  class="h-full bg-gradient-to-r ... rounded-full overflow-hidden"
  style="width: 20%"
>
  <div class="animate-shimmer ..."></div>
</div>
```

**アニメーション定義：**

```css
@keyframes shimmer {
  0% {
    transform: translateX(-100%); /* 左外側から開始 */
  }
  100% {
    transform: translateX(100%); /* 右外側へ終了 */
  }
}
```

---

### 3. UI 要素の振る舞い

- **ボタン & カード:**
  - `relative overflow-hidden` を必須とする（光沢レイヤーのため）。
  - ホバー時は、影（Glow）を拡散させ、内側の照り返しを強くする。
- **アイコン & テキスト:**
  - `drop-shadow` を多用し、内側から強く発光しているように見せる（Core Luminescence）。

---

## 📝 実装時のプロンプト例

AI にデザインを依頼する際は、以下の指示を含めてください。

> 「UI デザインは『Holographic Neon Noir (God Mode)』テーマを採用してください。
> 以下のデザインルール（Tailwind CSS）を厳守し、既存の HTML 構造を維持したまま `dark:` クラスを追加・修正してください。
>
> 1. **Glass Cover (濡れた質感):** `before` 擬似要素と `animate-pulse` を使用して、カード上部に濡れたような光沢と明滅を与える。
> 2. **Jewel Icons (宝石アイコン):** アイコンは `dark:!text-transparent` とグラデーションを使用して、内側から発光する宝石のように表現する。
> 3. **Futuristic Capsule (カプセル形状):** カードの角丸は `rounded-[2.5rem]` (40px) を厳守し、未来的な形状にする。
> 4. **Double Rim Light:** `border-t-white/40` と `inset shadow` を使用して、鋭いエッジとガラスの厚みを表現する。
> 5. **Breathing Glow:** 背景に呼吸する光のオーブを配置し、生命感を与える。

---

### 🎨 カードの階層と目立たせ方

**重要なカードは明るくする**

ダッシュボードのような複数カードがある場合、最も重要なカードを目立たせるために明るさを調整する。

```html
<!-- ❌ すべて同じ暗さ（目立たない） -->
<div class="dark:from-slate-900 dark:via-indigo-950 dark:to-slate-900">
  <!-- ✅ 主要カードは明るめ -->
  <div class="dark:from-cyan-600 dark:via-indigo-700 dark:to-purple-800"></div>
</div>
```

**階層の例：**

- **主要カード：** `dark:from-cyan-600 dark:via-indigo-700 dark:to-purple-800`
- **副次カード：** `dark:from-slate-900 dark:to-blue-950`

---

### 💧 Glass Cover（濡れた光沢）の最適な不透明度

**経験則：**

- **15%：** 薄すぎて目立たない
- **20%：** 最適（推奨）✅
- **25%：** パルスアニメーションと組み合わせると強すぎる

```html
<!-- ✅ 推奨 -->
before:from-white/20 before:to-transparent before:animate-pulse
```

**注意：** `animate-pulse` を使用する場合、不透明度を上げすぎると明滅が強すぎて目に優しくない。

---

### 📐 カプセル型カードでの要素配置

**問題：** 大きな角丸（60px 以上）では、端に近い要素がはみ出す可能性がある。

**解決策：** 端に近い要素には適度なマージンを設定する。

```html
<!-- ❌ はみ出す -->
<div class="rounded-[3.75rem]">
  <div class="absolute left-0">リボンバッジ</div>
</div>

<!-- ✅ マージンで調整 -->
<div class="rounded-[3.75rem]">
  <div class="ml-2">リボンバッジ</div>
</div>
```

---

### 📊 プログレスバーの正しい構造

**問題：** シマーエフェクトが色付きバーの範囲を超えて表示される。

**解決策：** 色付きバーに `relative` と `overflow-hidden` を追加する。

```html
<!-- ❌ 間違い：背景バーに relative -->
<div class="relative bg-gray-200 rounded-full overflow-hidden">
  <div class="bg-blue-500 rounded-full" style="width: 50%">
    <div class="absolute inset-0 animate-shimmer"></div>
  </div>
</div>

<!-- ✅ 正しい：色付きバーに relative -->
<div class="bg-gray-200 rounded-full overflow-hidden">
  <div
    class="relative bg-blue-500 rounded-full overflow-hidden"
    style="width: 50%"
  >
    <div class="absolute inset-0 animate-shimmer"></div>
  </div>
</div>
```

**キーポイント：**

- シマーの親要素（色付きバー）に `relative` が必要
- 色付きバーにも `overflow-hidden` を追加してシマーを範囲内に限定

---

### 📝 Post Card (投稿カード)

投稿カードは、タイムラインの中心となる要素であり、以下の特徴を持つ。

- **Capsule Shape:** `rounded-[3.75rem]` (60px) を採用し、非常に丸みを帯びた形状にする。
- **Reaction Area:** カード下部のリアクションエリアは、カード本体の丸みに合わせて `rounded-b-[3.75rem]` を適用し、一体感を持たせる。
- **Glass Cover:** カード全体に `before:h-[45%]` の Glass Cover を適用し、上部からの光沢を表現する。

```html
<div
  class="relative p-6 rounded-[3.75rem]
            bg-white dark:bg-slate-900/40 backdrop-blur-md
            border border-gray-200 dark:border-purple-500/30 dark:border-t-white/40
            shadow-lg dark:shadow-[0_0_20px_rgba(168,85,247,0.2)]
            overflow-hidden
            before:absolute before:inset-x-0 before:top-0 before:h-[45%]
            before:bg-gradient-to-b before:from-white/20 before:to-transparent
            before:rounded-t-[3.75rem] before:pointer-events-none before:animate-pulse"
>
  <!-- Content -->
  <div class="relative z-10">...</div>

  <!-- Reaction Area -->
  <div
    class="mt-0 pt-2 pb-1 bg-white/30 dark:bg-black/20 backdrop-blur-sm
              -mx-6 px-6 rounded-b-[3.75rem] relative z-20"
  >
    ...
  </div>
</div>
```

### 🖼 Modal (モーダル)

モーダルウィンドウもカプセル形状を採用し、浮遊感を強調する。

- **Shape:** `rounded-[3.75rem]`
- **Border:** `border-4` で太めの枠線をつけ、存在感を出す。
- **Shadow:** 強力なドロップシャドウとインナーシャドウを組み合わせる。

```html
<div
  class="bg-[#f8fafc] dark:bg-[#1a0b2e] w-full p-10 rounded-[3.75rem]
            border-4 border-white dark:border-purple-500/30 dark:border-t-white/40
            shadow-[20px_20px_60px_#d1d9e6,-20px_-20px_60px_#ffffff]
            dark:shadow-[0_0_50px_rgba(168,85,247,0.2),inset_0_0_0_1px_rgba(255,255,255,0.1)]
            relative overflow-hidden
            before:absolute before:inset-x-0 before:top-0 before:h-[20%]
            before:bg-gradient-to-b before:from-white/10 before:to-transparent
            before:rounded-t-[3.75rem] before:pointer-events-none"
>
  ...
</div>
```
