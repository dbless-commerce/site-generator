# 🛍️ DBless Multilingual eCommerce Website via WhatsApp

This project is a **database-free eCommerce site generator** that uses **WhatsApp** for handling customer orders and communication. It supports **multiple languages**, with each language version hosted on a separate GitHub Pages subdomain via **Git submodules**.

---

## 🌐 Key Features

- ✅ **No database needed** — Orders are placed via WhatsApp, avoiding complex data compliance issues.
- 🌍 **Multilingual support** — Turkish (`tr`), Arabic (`ar`), and English (`en`) versions managed through Git submodules.
- ⚙️ **Automated site generation** — Run a script to rebuild and deploy all language sites in one go.
- 🗂️ **Clean, structured repo** — Uses centralized JSON files and organized folders for data and images.

---

## 📁 Project Structure

```
site-generator/
├── .vscode/            # VSCode config
├── files/              # JSON data & images
├── scripts/            # Automation scripts
├── site-tr/            # Turkish site (submodule)
├── site-ar/            # Arabic site (submodule)
├── site-en/            # English site (submodule)
├── .gitmodules         # Git submodule configs
├── LICENSE             # License info
└── README.md           # Project overview
```

---

## 🔄 How It Works

### 🧩 Language Submodules

Each language version is a separate GitHub repository, added as a Git submodule to this main generator repo. This allows you to:

- Host different language sites at different subdomains (`tr.example.com`, `en.example.com`, etc.)
- Manage content in isolation while sharing a common structure

### ⚙️ Data Management

Located in the `files/` directory:

- `site.json`: Site-wide configuration (e.g., branding, layout).
- `product.json`: Product listings.

To update content:

1. Edit the JSON files.
2. Run the update script (see below).

---

## 🚀 Generate & Deploy Sites

To build and update all language sites:

```bash
./scripts/generate.sh
```

This script will:

- Read from `site.json`, `company, json`and `product.json`
- Generate static pages for each language

To build and update all language sites:

```bash
./scripts/push-sites.sh
```
This script will:
- Commit and push updates to each submodule

> ⚠️ Make sure your submodules are initialized before running this!

---

## 🧠 Client-Side Functionality

The `programmatic/` folder (within each language site) includes:

- Shopping basket logic
- WhatsApp integration
- UI interactivity for a seamless user experience

These scripts are included automatically when you generate the sites.

---

## 🖼️ Image Organization

All images are managed under the `files/` directory with clear conventions:

- **Product Images:**  
  `files/products/`  
  Match image filenames to product names.

- **Page Images:**  
  `files/img/pages/`  
  Match image filenames to page titles.

> 📝 **Note:** File names must match exactly to avoid display errors.

---

## 🛠️ Development Setup

Clone the repo and initialize submodules:

```bash
git clone <repo-url>
cd site-generator
git submodule update --init --recursive
```

After making changes to JSON files or static content:

```bash
./scripts/update.sh
```

---

## 🪪 License

This project is licensed under the [MIT License](./LICENSE).

---

## 📬 Contributions

Feel free to open issues or PRs to improve the generator or add new features.

---
