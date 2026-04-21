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

```plaintext
SITE-GENERATOR/
├── generate-all.sh              # Main generation script
├── files/                       # Static assets used by the generated sites
│   ├── css/                     # Global CSS styles
│   ├── img/                     # Images and icons
│   └── js/                      # JavaScript files
│
├── scripts/                     # All automation scripts
│   ├── generators/              # Generators for specific content
│   │   ├── html-generators.sh   # Generates HTML pages
│   │   └── product-generators.sh# Generates product-related pages/content
│   │
│   ├── tasks/                   # Utility tasks for building assets
│   │   ├── copy-images.sh       # Copies images to the build folder
│   │   ├── create-css.sh        # Builds/merges CSS files
│   │   ├── create-pages.sh      # Creates static pages
│   │   ├── create-products.sh   # Creates product pages
│   │   └── merge-js.sh          # Merges and processes JS functionality
│   │
│   └── utils/                   # Helper functions for scripts
│       └── utils.sh             # Common shell utilities
│       └── push-sites.sh        # Deploy/push sites to the server or repo
│
├── site-ar/                     # Generated site content in Arabic
├── site-en/                     # Generated site content in English
├── site-tr/                     # Generated site content in Turkish
│
└── .editorconfig                # Editor configuration for consistent coding style
└── .gitmodules                  # Git submodules configuration
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

Each language version is a separate GitHub repository, added as a Git submodule to this main generator repo.

- Host different language sites at different subdomains (`tr.example.com`, `en.example.com`, etc.)
- Manage content in isolation while sharing a common structure.

📖 [Learn more about Git Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)

⚠️ **Why initialize submodules?**  
Because the language folders (`site-ar`, `site-en`, `site-tr`) are *not* regular folders but linked repositories.  
Without initializing, they will be empty placeholders.

```bash
git submodule update --init --recursive
```

📖 [GitHub Pages documentation](https://docs.github.com/en/pages)

---

## 🛒 Order Flow

```mermaid
sequenceDiagram
    participant Customer
    participant Website
    participant WhatsApp
    participant Admin
    participant TrackingNotebook

    Customer->>Website: Browse products
    Customer->>Website: Add product to cart
    Website->>WhatsApp: Generate order message link
    Customer->>WhatsApp: Send order via WhatsApp
    WhatsApp->>Admin: Receive order message
    Admin->>TrackingNotebook: Generate reference number
    Admin->>TrackingNotebook: Store customer address
    Admin->>Customer: Confirm order with reference number
```

---

## 📝 Managing Page Content

All text and configuration for each language site are stored in the `data/site.json` file inside the respective language folder (`site-ar`, `site-en`, `site-tr`).

- **Static text** (homepage content, about page, etc.) is stored as key/value pairs.
- **Images** are stored in `files/img/` and referenced in JSON files.
- **Admin editing**: These JSON files can be updated directly in GitHub, or through a planned admin interface for non-technical editors.

---

## 📒 Order Tracking Notebook

For every order:

1. The admin assigns a **Reference Number** to the customer’s address in chat.
2. The customer’s **address** and order details are stored in a simple tracking notebook (JSON or CSV) for future reference and repeat sales.

Example structure (`tracking-notebook.json`):

```json
[
  {
    "referenceNumber": "REF-20250805-01",
    "customerName": "Ali Ahmad",
    "address": "Gaza City, Palestine",
    "orderDetails": [
      {"productId": "p500", "quantity": 2}
    ],
    "status": "Pending"
  }
]
```

---

## 💰 Product Price & Shipping Cost

- **Current prices** are stored in `product.json` for each language site.
- **Shipping costs** are stored in `data/shipping.json` in each language site.

Since these values change frequently, maintain a **history** in a separate file:

Example (`price-history.json`):

```json
[
  {
    "productId": "p500",
    "date": "2025-08-01",
    "price": 210,
    "shippingCost": 20
  }
]
```

This allows you to track changes over time and adjust pricing easily.

---

## ➕ Adding New Content

### 🆕 Product JSON Structure

```jsonc
{
  "id": "p500",
  "name": "Erzincan Tulum",
  "url": "erzincan-tulum",
  "price": 210,
  "currency": "USD",
  "shortDesc": "Short desc",
  "metaDesc": "Meta desc",
  "keywords": "cheese, organic",
  "image": "/static/img/products/erzincan-tulum.jpg",
  "weight": "500g",
  "category": "cheese",
  "featured": true,
  "inStock": true
}
```

Add your product in `site-<lang>/data/product.json` then run:

```bash
./generate-all.sh
```

---

### 🌍 Add a New Language

1. Create a new repo for the language (e.g., `site-fr`).
2. Add it as a submodule:
```bash
git submodule add <repo-url> site-fr
```
3. Create the data/ folder inside the new language repo and add the required JSON files.
4. Translate content in the JSON files to the new language.
5. Run the generator script to build the site:
```bash
./generate-all.sh
```

# 4. Generate
./update.sh fr
```

### 📄 Add a New Page

1. Update `site-<lang>/data/site.json`
2. Add a new page entry
3. Run:
```bash
./scripts/tasks/create-pages.sh
```

---

## 🚀 Build & Deploy in One Step

Instead of running separate generate and deploy commands, use:

```bash
./scripts/utils/push-sites.sh
```

This will generate all sites and deploy them to their respective submodules in one go.

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

```bash
./generate-all.sh
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

Feel free to open issues or PRs to improve the generator or add new features.
