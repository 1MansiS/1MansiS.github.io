#!/bin/bash
# ============================================================
# setup.sh — Run this ONCE before using the new site files
#
# What it does:
#   1. Removes old minima theme files that conflict with our custom design
#   2. Runs bundle install for the new minimal Gemfile
#
# Usage:
#   cd /path/to/your/local/repo
#   bash setup.sh
# ============================================================

echo "🧹 Removing old theme files that conflict with custom design..."

# Remove minima SCSS (this was overriding our CSS)
rm -rf _sass/

# Remove old includes (minima's head.html was loading the wrong CSS)
# (We provide our own _includes/ with override stubs)

# Remove old compiled scss entry point if it exists
rm -f assets/main.scss
rm -f assets/css/main.css

# Remove old index.html or index.markdown if they exist alongside our index.md
rm -f index.html
rm -f index.markdown

echo "📦 Installing gems (no minima this time)..."
bundle install

echo ""
echo "✅ Done! Now run:  bundle exec jekyll serve"
echo "   Then open:      http://localhost:4000"
