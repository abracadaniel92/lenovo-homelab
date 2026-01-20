# Home Assistant Themes Guide

## 🎨 Popular Themes

### Dark Themes

#### 1. **iOS Dark Mode** ⭐ Most Popular
- **Style**: Apple iOS-inspired with blurred backgrounds
- **Best for**: Wall-mounted tablets, modern look
- **GitHub**: `basnijholt/lovelace-ios-dark-mode-theme`

#### 2. **Noctis**
- **Style**: High-contrast dark theme, easy on eyes
- **Colors**: Deep navy, charcoal, vibrant accents
- **GitHub**: `aaron5670/noctis-theme`

#### 3. **Synthwave** 🌈
- **Style**: Retro-future 80s aesthetic
- **Colors**: Neon pinks, purples, cyans
- **GitHub**: `bbbenji/synthwave-hass`

#### 4. **Nord**
- **Style**: Clean, minimal dark theme
- **Colors**: Arctic blue palette
- **GitHub**: `arallsopp/hass-nord-theme`

#### 5. **Rose Pine**
- **Style**: Soft, pastel dark theme
- **Colors**: Rose and pine tones
- **GitHub**: `caule/hass-rose-pine-theme`

### Light Themes

#### 6. **iOS Light Mode**
- **Style**: Apple iOS light theme
- **Best for**: Bright environments
- **GitHub**: `basnijholt/lovelace-ios-light-mode-theme`

#### 7. **Google Home Theme**
- **Style**: Google Home app aesthetic
- **Colors**: Clean white/soft gray
- **GitHub**: `N-l1/lovelace-google-home-theme`

#### 8. **Minimalist Desktop**
- **Style**: Flat, clean "magazine" look
- **Best for**: Desktop displays
- **GitHub**: Various minimalist themes

### Special Themes

#### 9. **Caule Themes Pack**
- **Includes**: Rose Pine, Everforest, Nord variants
- **Style**: Soft pastel palettes
- **GitHub**: `caule/hass-themes`

#### 10. **Dracula**
- **Style**: Dracula color scheme
- **Colors**: Dark purple/red accents
- **GitHub**: `dracula/theme`

## 📥 Installation Methods

### Method 1: Manual Installation (No HACS Needed)

#### Step 1: Create Themes Directory
```bash
cd /home/docker-projects/homeassistant
docker compose exec homeassistant mkdir -p /config/themes
```

#### Step 2: Download Theme File
```bash
# Example: iOS Dark Mode
docker compose exec homeassistant bash -c "cd /config/themes && wget https://raw.githubusercontent.com/basnijholt/lovelace-ios-dark-mode-theme/main/themes/ios-dark-mode.yaml"
```

#### Step 3: Rename File (Important!)
The filename (without .yaml) becomes the theme name in Home Assistant:
```bash
# Rename to match theme name
docker compose exec homeassistant bash -c "cd /config/themes && mv ios-dark-mode.yaml ios-dark-mode.yaml"
```

#### Step 4: Reload Themes
- Go to: **Developer Tools** → **YAML** → Click **"Themes"** under "Reload Configuration"
- Or restart Home Assistant

#### Step 5: Apply Theme
- Click your **User Profile** (bottom of sidebar)
- Select **Theme** dropdown
- Choose your theme

### Method 2: Using HACS (If Working)

1. **HACS** → **Frontend** → **Explore & Download Repositories**
2. Search for theme name
3. Click **Download**
4. Reload themes (Developer Tools → YAML → Themes)
5. Apply in User Profile

## 🔧 Quick Install Scripts

### Install iOS Dark Mode
```bash
cd /home/docker-projects/homeassistant
docker compose exec homeassistant bash -c "
  mkdir -p /config/themes && \
  cd /config/themes && \
  wget -O ios-dark-mode.yaml https://raw.githubusercontent.com/basnijholt/lovelace-ios-dark-mode-theme/main/themes/ios-dark-mode.yaml
"
```

### Install Noctis
```bash
cd /home/docker-projects/homeassistant
docker compose exec homeassistant bash -c "
  mkdir -p /config/themes && \
  cd /config/themes && \
  wget -O noctis.yaml https://raw.githubusercontent.com/aaron5670/noctis-theme/main/themes/noctis.yaml
"
```

### Install Synthwave
```bash
cd /home/docker-projects/homeassistant
docker compose exec homeassistant bash -c "
  mkdir -p /config/themes && \
  cd /config/themes && \
  wget -O synthwave.yaml https://raw.githubusercontent.com/bbbenji/synthwave-hass/main/themes/synthwave.yaml
"
```

## 📋 Theme URLs (Direct Download)

Replace `THEME_FILE.yaml` with the actual filename from the repo:

- **iOS Dark**: `https://raw.githubusercontent.com/basnijholt/lovelace-ios-dark-mode-theme/main/themes/ios-dark-mode.yaml`
- **Noctis**: `https://raw.githubusercontent.com/aaron5670/noctis-theme/main/themes/noctis.yaml`
- **Synthwave**: `https://raw.githubusercontent.com/bbbenji/synthwave-hass/main/themes/synthwave.yaml`
- **Nord**: `https://raw.githubusercontent.com/arallsopp/hass-nord-theme/main/themes/nord.yaml`
- **Rose Pine**: `https://raw.githubusercontent.com/caule/hass-rose-pine-theme/main/themes/rose-pine.yaml`

## 🎯 Recommended Setup

1. **Start with iOS Dark Mode** - Most polished, works great
2. **Try Synthwave** - If you want something fun/unique
3. **Use Noctis** - If you prefer high contrast

## 💡 Tips

- **Multiple Themes**: You can install multiple themes and switch between them
- **Per-User**: Each user can have their own theme preference
- **Testing**: Reload themes (don't need full restart) to test changes
- **Customization**: Edit theme YAML files directly to customize colors

## 🔍 Find More Themes

- **HACS Frontend Section**: Browse themes if HACS is working
- **GitHub**: Search "home assistant theme" for more options
- **Community**: Check Home Assistant Community Forums

## ✅ Verify Configuration

Your `configuration.yaml` should have:
```yaml
frontend:
  themes: !include_dir_merge_named themes
```

This is already configured! ✅

