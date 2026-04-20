# 🛍️ DBless Multilingual eCommerce Site Generator

A **database-free** eCommerce site generator that routes orders through **WhatsApp**. Maintain one source of data, generate static sites in **multiple languages**, and deploy each one to its own subdomain.

> 🇬🇧 English · 🇸🇦 العربية · 🇹🇷 Türkçe — all built from shared templates, one JSON file per site.

---

## 📑 Table of Contents

- [Quick Start](#-quick-start)
- [Key Features](#-key-features)
- [Project Structure](#-project-structure)
- [How It Works](#-how-it-works)
- [Scripts Reference](#-scripts-reference)
- [Data Files](#-data-files)
- [Adding a New Language](#-adding-a-new-language)
- [Adding a New Page or Product](#-adding-a-new-page-or-product)
- [Image Management](#-image-management)
- [Shipping Configuration](#-shipping-configuration)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

---

## 🚀 Quick Start

```bash
# 1. Clone with submodules
git clone <repo-url>
cd site-generator
git submodule update --init --recursive

# 2. Install required dependencies
#   - bash 4+
#   - jq  (JSON parser — required)
#   - node + npx (for local preview only)

# 3. Build every language site
./generate-all.sh

# 4. Preview locally (serves site-en on http://localhost:8000)
npx http-server site-en -p 8000 -c-1
```

Made a change? Use the **incremental update** script:

```bash
./update.sh            # detects & rebuilds only what changed
./update.sh en         # force-rebuild one language
./update.sh --all      # rebuild everything (same as generate-all.sh)
```

---

## ✨ Key Features

| Feature | What it gives you |
| --- | --- |
| 🗄️ No database | Orders flow through WhatsApp — no backend, no compliance overhead |
| 🌍 Multilingual | Arabic / English / Turkish sites, each a git submodule at its own subdomain |
| ⚡ Incremental builds | `update.sh` only rebuilds sites whose data actually changed |
| 🧩 JSON-driven | All content lives in `site-<lang>/data/*.json` — edit once, regenerate, done |
| 🖼️ Image overrides | Per-site image themes via `images` map in `site.json`, with sensible defaults |
| 📦 Smart shipping | Centralized rules in `shippingData.json`, loaded once and cached client-side |
| 📝 Templates | `samples/` contains starter JSONs for every data file — copy & fill |

---

## 📁 Project Structure

```
site-generator/
├── files/                  # Shared assets (CSS, JS, default images)
│   ├── css/
│   ├── js/main.js          # Basket, WhatsApp, shipping logic
│   └── img/pages/          # Default page images (+ samples/)
│
├── scripts/
│   ├── tasks/              # Pipeline steps (pages, css, products, images, js)
│   ├── generators/         # HTML/product template generators
│   └── utils/              # Shared bash helpers + push-sites.sh
│
├── samples/                # 📋 Template JSONs — copy these when scaffolding
│   ├── site-template.json
│   ├── company-template.json
│   ├── product-template.json
│   ├── page-template.json
│   ├── shipping-template.json
│   └── priceHistory-template.json
│
├── site-en/  site-ar/  site-tr/   # Per-language sites (git submodules)
│   └── data/*.json         # Content for that locale
│
├── generate-all.sh         # Full rebuild across all languages
├── update.sh               # Incremental rebuild — detects changes
└── index.html              # Language landing page
```

---

## 🔄 How It Works

1. **You edit JSON** in `site-<lang>/data/` (site config, products, shipping, etc.).
2. **Run `./update.sh`** — it checks mtimes against `.last_build`, decides which sites need regenerating, then pipes:
   - `create-pages.sh` → renders HTML pages from templates
   - `create-products.sh` → builds per-product pages
   - `create-css.sh` → bundles CSS
   - `copy-images.sh` → copies defaults + applies per-site overrides
   - `create-js.sh` → merges shared JS into each site
3. **The result** lands inside each submodule (`site-en/`, `site-ar/`, `site-tr/`), ready to commit and push independently.

### 🧱 Language submodules

Each language site is its own GitHub repo, included here as a submodule. That lets you:
- Deploy each to a separate subdomain (`en.example.com`, `ar.example.com`, …)
- Version and release locales independently
- Share the generator, templates, and assets across all of them

---

## 🛠️ Scripts Reference

| Script | Purpose |
| --- | --- |
| `./generate-all.sh` | Full rebuild of every language site (runs all pipeline tasks) |
| `./update.sh` | Incremental rebuild — auto-detects changed data or shared assets |
| `./update.sh <lang>...` | Force-rebuild specific languages (e.g. `./update.sh en tr`) |
| `./update.sh --all` | Force-rebuild everything |
| `scripts/utils/push-sites.sh` | Commit & push each submodule |
| `scripts/tasks/create-pages.sh` | Generate HTML pages for a language |
| `scripts/tasks/create-products.sh` | Generate product pages |
| `scripts/tasks/create-css.sh` | Bundle CSS into each site |
| `scripts/tasks/copy-images.sh` | Copy default page images + apply overrides |
| `scripts/tasks/create-js.sh` | Merge shared JS into each site |

---

## 📄 Data Files

Every language site expects these JSON files in `site-<lang>/data/`:

| File | What it contains |
| --- | --- |
| `site.json` | Branding, menu, page copy, optional `images` override map |
| `company.json` | Company info (name, addresses, contact, socials) |
| `product.json` | Products, categories, product settings |
| `shippingData.json` | Weight-based shipping rules + free-shipping threshold |
| `priceHistory.json` | Historical price changes per product (optional) |
| `home.json`, `404.json`, `sitemap.json` | Per-page content not already in `site.json` |

**Don't start from scratch** — copy from `samples/`:

```bash
cp samples/site-template.json     site-fr/data/site.json
cp samples/product-template.json  site-fr/data/product.json
cp samples/shipping-template.json site-fr/data/shippingData.json
```

---

## ➕ Adding a New Language

```bash
# 1. Create the submodule (or a plain directory while prototyping)
mkdir -p site-fr/data

# 2. Seed data from templates
for t in site company product shipping; do
  cp "samples/${t}-template.json" "site-fr/data/${t/shipping/shippingData}.json"
done

# 3. Register the language in scripts/utils/utils.sh (LANGUAGES array)

# 4. Generate
./update.sh fr
```

---

## 📰 Adding a New Page or Product

**New page:**

```bash
cp samples/page-template.json site-en/data/faq.json
# edit faq.json with your content, then:
./update.sh en
```

**New product:** add an entry to the `products` array in `site-<lang>/data/product.json` (use `samples/product-template.json` as a field reference), drop the product image into `files/img/products/`, then `./update.sh`.

---

## 🖼️ Image Management

- **Default page images** live in `files/img/pages/` (`header.jpg`, `about.jpg`, `footer.jpg`, …).
- **Product images** live in `files/img/products/` — filename must match the product's `url` slug.
- **Themed sample images** live in `files/img/pages/samples/` (e.g. `white-back-brown-dogs.jpg`, `sky-back-pink-flamingos.jpg`).

### Per-site image overrides

Add an `images` map to any `site-<lang>/data/site.json` to swap defaults for that language:

```json
{
  "images": {
    "header": "white-back-brown-dogs.jpg",
    "about":  "cream-back-orange-cats.jpg",
    "footer": "sky-back-pink-flamingos.jpg"
  }
}
```

`copy-images.sh` copies defaults first, then replaces them with overrides where defined.

---

## 🚚 Shipping Configuration

Shipping is **data-driven**, not hardcoded. Edit `site-<lang>/data/shippingData.json`:

```json
{
  "freeShippingWeightKg": 15,
  "rules": [
    { "maxWeightKg": 0.5, "extraCost": 0 },
    { "maxWeightKg": 1,   "extraCost": 5 },
    { "maxWeightKg": 2,   "extraCost": 10 },
    { "maxWeightKg": 5,   "extraCost": 20 },
    { "maxWeightKg": 10,  "extraCost": 35 },
    { "maxWeightKg": 15,  "extraCost": 50 }
  ]
}
```

`main.js` loads this once on init, caches it, and uses it for the basket summary and the WhatsApp order message.

---

## 🧯 Troubleshooting

| Symptom | Fix |
| --- | --- |
| `Missing dependencies: jq` | Install `jq` — `winget install jqlang.jq` (Windows), `brew install jq` (mac), `apt install jq` (Linux) |
| `./update.sh` rebuilds nothing | Delete `.last_build` or run `./update.sh --all` |
| Images not replaced by overrides | Make sure the file exists in `files/img/pages/samples/` and the key in `site.json` `images` matches the default filename |
| Shipping numbers look wrong | Validate `shippingData.json` with `jq . site-en/data/shippingData.json` — JSON can't contain comments |
| Submodule dir is empty | `git submodule update --init --recursive` |

---

## 🤝 Contributing

Issues and PRs are welcome. When adding a feature:
1. Update or add a template in `samples/` if you introduced a new JSON field.
2. Keep shared logic in `files/` and `scripts/` — per-site files should only hold content.
3. Run `./update.sh --all` locally before opening a PR.

---

## 🪪 License

[MIT](./LICENSE)
