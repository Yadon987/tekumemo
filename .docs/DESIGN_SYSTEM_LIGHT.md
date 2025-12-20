# Role

あなたは世界最高峰のフロントエンドエンジニア兼 UI デザイナーです。
既存の機能要件および**既存のダークモード設定**を完全に維持したまま、指定されたデザインシステム（ライトモード用）を適用してください。

# ⚠️ Critical Constraints (絶対厳守の制約事項)

作業を行うにあたり、以下のルールを絶対に守ってください。機能や既存のダークモード表示を破壊することは許されません。

1. **ロジックの保全:**

   - JavaScript / TypeScript / Ruby(ERB) / PHP などのロジックコードは一切変更・削除しないでください。
   - `onClick`, `onSubmit`, `onChange` などのイベントハンドラ属性は絶対に触らないでください。

2. **DOM 構造と識別子の維持:**

   - `id` 属性、`data-` 属性は絶対に変更・削除しないでください（JS からの参照維持のため）。

3. **【最重要】ダークモード設定の完全保護:**

   - **`dark:` プレフィックスが付いているクラスは、いかなる理由があっても削除・変更しないでください。**
   - 今回適用するデザインは「ライトモード（Default）」用です。追加・変更するスタイルが、ダークモード時の表示を崩さないようにしてください。
   - 必要であれば、変更するプロパティに対して明示的に `dark:既存の色` などを再定義し、ライトモード用の変更がダークモードに漏れ出さないようにコードを調整してください。
   - **CSS クラス定義を使用する場合:** `.crystal-card` などのカスタムクラスを定義する際は、必ず `:is(.dark .crystal-card)` などでダークモード時のスタイルをリセット（無効化）してください。

4. **変更の範囲:**

   - 変更してよいのは「Tailwind CSS のクラス」と「装飾目的の HTML 構造」のみです。
   - テキストコンテンツは変更しないでください。

5. **安全な適用:**
   - レイアウト崩れを防ぐため、`flex`, `grid`, `absolute` などの配置関連クラスの変更は慎重に行い、構造維持を最優先してください。

---

# Design System: Crystal Claymorphism (Light Mode)

## 🎨 デザインコンセプト

**「触りたくなるような柔らかさと、キャンディのような透明感（ポップ × クリア × わくわく）」**

- **キーワード:** Claymorphism（クレイモーフィズム）, Crystal Clear（透明感）, Candy Color（キャンディカラー）, Soft & Pop.

## 🛠️ スタイリングルール (Tailwind CSS)

### 1. 形状 (Shape)

- **角丸:** 基本的に `rounded-3xl` (24px) 以上を使用する。
  - カード: `rounded-[2.5rem]` (40px)
  - ボタン: `rounded-full` (完全な円/カプセル)
- **意図:** 鋭利な角を排除し、徹底的に「柔らかさ」を強調する。

### 2. 質感と立体感（Crystal Claymorphism Core）

**「触りたくなるような、ぷるぷるとしたキャンディーの質感」**を以下の 4 つの要素の組み合わせで実現する。これらは**セットで適用**すること。

#### A. クリスタルシャドウ (3-Layer Shadow)

単なる影ではなく、**「浮遊感」「ハイライト」「ぷっくり感」**を同時に表現する 3 層構造のシャドウを使用する。

- **Layer 1 (Drop Shadow):** 右下にテーマカラーの半透明影 (`20px 20px 60px rgba(Color, 0.2)`)
- **Layer 2 (Highlight Shadow):** 左上に強い白の影 (`-20px -20px 60px rgba(255, 255, 255, 0.8)`)
- **Layer 3 (Puffy Inset):** 内側にぷっくり感を出すインセット影 (`inset -5px -5px 15px rgba(Color, 0.05), inset 5px 5px 15px rgba(255, 255, 255, 0.9)`)

**Tailwind Arbitrary Value Example:**

```css
shadow-[20px_20px_60px_rgba(59,130,246,0.2),-20px_-20px_60px_rgba(255,255,255,0.8),inset_-5px_-5px_15px_rgba(59,130,246,0.05),inset_5px_5px_15px_rgba(255,255,255,0.9)]
```

#### B. キャンディー質感 (Candy Texture)

透明感と光沢を出すために、以下の 2 つを必ず実装する。

1.  **White Gradient Overlay:** 背景に白から透明へのグラデーションを重ねる。
    - `bg-gradient-to-br from-white/80 via-white/40 to-transparent`
    - **重要:** ダークモードでは必ず無効化する (`dark:bg-none`)。
2.  **Blurry Gradient Orbs:** カードの隅（右上・左下）に、テーマカラーのぼかし円（オーブ）を配置し、内側から色が滲み出る表現をする。
    - HTML: `<div class="absolute -top-10 -right-10 w-40 h-40 bg-gradient-to-br from-Color/20 to-Color/20 rounded-full blur-2xl pointer-events-none dark:hidden"></div>`

#### C. クリスタルリム (Crystal Rim)

カードのフチは、**「白いハイライト」**と**「色の反射」**を分けて表現する。

- **Border:** 白の半透明 (`border-2 border-white/60`) でハイライトを入れる。**ここに色を付けてはいけない。**
- **Color Reflection:** 左上からの極細のインセットシャドウ (`inset 2px 2px 0px rgba(Color, 0.3)`) で、ガラスの中に色が閉じ込められているような表現をする。

**Shadow Definition Update:**

```css
/* Shadow + Puffy Inset + Color Reflection */
shadow-[..., inset_2px_2px_0px_rgba(Color,0.3)]
```

#### D. ダークモード保護 (Dark Mode Safety)

Crystal Claymorphism は**ライトモード専用**のデザインである。

- ライトモード用の装飾（Orbs, Gradient Overlay, Light Shadows）は、ダークモードでは**完全に非表示・無効化**すること。
- `dark:hidden`, `dark:bg-none`, `dark:shadow-none` (or dark specific shadow) を徹底する。

### 3. カラーパレット (Color Palette)

- **Base (背景):** `bg-[#fdfbf7]` (Warm White) や `bg-slate-50`。
- **Shadow (影):** 各要素のテーマカラーに合わせる（青なら青い影）。
- **Icon (アイコン):** 鮮やかな原色に近い色（`text-blue-500`, `text-orange-500`）を使用し、ポップさを維持する。

### 4. インタラクション (Micro-interactions)

- **Hover:** `hover:scale-105` (少し膨らむ) + 影の色を少し濃くする。
- **Active:** `active:scale-95` (押される)。

---

## 📝 実装時のプロンプト例

AI にデザインを依頼する際は、以下の指示を含めてください。

> 「UI デザインは『Crystal Claymorphism』テーマを採用してください。
> 具体的には、TailwindCSS を使用して以下の特徴を持たせてください：
>
> 1. **カラーシャドウ:** `box-shadow` の影色には黒を使わず、要素のテーマカラー（青、オレンジ等）の半透明色 (`rgba(..., 0.2)`) を使用して透明感を出す。
> 2. **ぷっくり感:** `radial-gradient` で中央を明るくし、`inset` シャドウで縁の丸みを強調する。
> 3. **輪郭:** ボーダーには `rgba(255, 255, 255, 0.6)` を使用し、背景との境界を適度にはっきりさせる。
> 4. **形状:** 角丸は `rounded-[2.5rem]` (40px) を基本とし、特別なカードには `rounded-[3.75rem]` (60px) を使用する。
> 5. **アイコン:** 鮮やかな色 (`text-blue-500` 等) を使用し、黒くしない。」

---

## 📊 統計・分析ページ (Stats) 特別ガイドライン

統計ページなどの「データを見せる」画面では、通常の Crystal Claymorphism をさらに発展させた**「Premium Crystal」**スタイルを適用します。

### 1. 形状 (Premium Shape)

- **極端なカプセル形状:** `rounded-[3.75rem]` (60px) を基本とします。
  - これにより、通常のカード (`rounded-[2.5rem]`) よりもさらに未来的で特別な印象を与えます。

### 2. 質感 (Glass & Soft Shadow)

- **Glass Cover (光沢):**
  - カードの上部に薄い光沢を追加し、ガラスのような質感を表現します。
  - `before:absolute before:inset-x-0 before:top-0 before:h-[45%] before:bg-gradient-to-b before:from-white/15 before:to-transparent`
- **Soft Shadow (浮遊感):**
  - 影は「濃く」するのではなく「薄く、広く」拡散させます。
  - `shadow-clay-card` (opacity 0.1~0.3) を使用。

### 3. タイポグラフィと視認性

- **見出し (Title):**
  - ライトモードでは**視認性を最優先**し、`text-slate-800` などの濃い色を使用します。
  - **重要:** ダークモードのネオン表現 (`text-transparent bg-clip-text ...`) と共存させるため、必ず以下のように記述します。
  - `class="text-slate-800 dark:text-transparent dark:bg-clip-text ..."`
- **数字 (Numbers):**
  - データの数字はグラデーションテキスト (`bg-clip-text text-transparent`) を使用し、ポップさを演出します。

### 4. ダークモードとの完全共存 (重要)

- **形状の統一:** ライト/ダークで `rounded` の値を変えないこと。シルエットを一致させることで、モード切替時の違和感をなくします。
- **影の切り替え:**
  - ライト: `shadow-clay-card` (色付きの影)
  - ダーク: `dark:shadow-[...]` (発光する影)
  - これらを `class="..."` 内で併記し、完全に分離して管理します。
