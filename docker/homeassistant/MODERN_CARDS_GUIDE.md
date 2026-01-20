# Modern Home Assistant Cards Guide

Beyond Mushroom Cards - here are the most modern, sleek card options!

## 🚀 Top Modern Cards (2025-2026)

### 1. **Bubble Card** ⭐ Most Modern!
- **Style**: iOS/Android app-like with slide-up popups
- **Why Modern**: Rounded design, haptic feedback, integrated sliders
- **Best For**: Mobile-first dashboards, premium feel
- **GitHub**: `nervetattoo/bubble-card`

### 2. **UI-Lovelace-Minimalist** ⭐ Framework
- **Style**: Cohesive, uniform design system
- **Why Modern**: Blueprint-based, professional look
- **Best For**: Entire dashboard redesign, consistent styling
- **GitHub**: `UI-Lovelace-Minimalist/UI`

### 3. **Custom Button Card** ⭐ Highly Customizable
- **Style**: Can look like anything with CSS
- **Why Modern**: Full CSS control, animations, templates
- **Best For**: Power users, unique designs
- **GitHub**: `custom-cards/button-card`

### 4. **Paper Buttons Row**
- **Style**: Compact, high-density button rows
- **Why Modern**: Space-efficient, clean control bars
- **Best For**: Quick actions, scene controls
- **GitHub**: `jimz011/paper-buttons-row`

### 5. **Home Assistant Native Tile Cards**
- **Style**: Built-in, tile-based design
- **Why Modern**: Official HA design language
- **Best For**: No installation needed, native support
- **How**: Built into Home Assistant Core

### 6. **ApexCharts Card**
- **Style**: Beautiful, interactive graphs
- **Why Modern**: Professional data visualization
- **Best For**: Sensor data, energy monitoring
- **GitHub**: `RomRider/apexcharts-card`

### 7. **Mini Graph Card**
- **Style**: Clean, minimal sensor graphs
- **Why Modern**: Simple, elegant data display
- **Best For**: Temperature, humidity trends
- **GitHub**: `kalkih/mini-graph-card`

### 8. **Card Mod**
- **Style**: Add custom CSS to any card
- **Why Modern**: Full styling control
- **Best For**: Advanced customization
- **GitHub**: `thomasloven/lovelace-card-mod`

## 📥 Installation Methods

### Method 1: Manual Installation (No HACS)

#### Step 1: Download Card Files
```bash
cd /home/docker-projects/homeassistant
docker compose exec homeassistant bash -c "
  mkdir -p /config/www/community && \
  cd /config/www/community
"
```

#### Step 2: Download Each Card
```bash
# Bubble Card
wget -O bubble-card.js https://github.com/nervetattoo/bubble-card/releases/latest/download/bubble-card.js

# Custom Button Card
wget -O button-card.js https://github.com/custom-cards/button-card/releases/latest/download/button-card.js

# Mini Graph Card
wget -O mini-graph-card-bundle.js https://github.com/kalkih/mini-graph-card/releases/latest/download/mini-graph-card-bundle.js

# ApexCharts Card
wget -O apexcharts-card.js https://github.com/RomRider/apexcharts-card/releases/latest/download/apexcharts-card.js

# Card Mod
wget -O card-mod.js https://github.com/thomasloven/lovelace-card-mod/releases/latest/download/card-mod.js
```

#### Step 3: Add to Resources
1. Go to: **Settings → Dashboards → Resources**
2. Click **+ Add Resource**
3. Enter URL: `/local/community/CARD_NAME.js`
4. Set Resource Type: **JavaScript Module**
5. Click **Create**

#### Step 4: Reload
- Clear browser cache (Ctrl+Shift+R)
- Cards will appear in card picker

### Method 2: Via HACS (If Working)

1. **HACS → Frontend → Explore & Download**
2. Search for card name
3. Click **Download**
4. Restart Home Assistant

## 🎨 Card Examples

### Bubble Card Example
```yaml
type: custom:bubble-card
entity: light.living_room
name: Living Room
icon: mdi:sofa
```

### Custom Button Card Example
```yaml
type: custom:button-card
entity: switch.kitchen
name: Kitchen
icon: mdi:chef-hat
tap_action:
  action: toggle
```

### Mini Graph Card Example
```yaml
type: custom:mini-graph-card
entities:
  - entity: sensor.temperature
    name: Temperature
hours_to_show: 24
points_per_hour: 0.5
```

### ApexCharts Card Example
```yaml
type: custom:apexcharts-card
graph_span: 24h
series:
  - entity: sensor.temperature
    name: Temperature
    type: line
```

## 🎯 Recommendations

### For Most Modern Look:
1. **Bubble Card** - Feels like a premium app
2. **UI-Lovelace-Minimalist** - Complete design system
3. **Custom Button Card** - Ultimate flexibility

### For Data Visualization:
1. **ApexCharts Card** - Professional graphs
2. **Mini Graph Card** - Simple, clean trends

### For Advanced Users:
1. **Card Mod** - Full CSS control
2. **Custom Button Card** - Template system

## 💡 Quick Comparison

| Card | Modern Look | Ease of Use | Customization |
|------|-------------|-------------|----------------|
| Bubble Card | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| UI-Lovelace-Minimalist | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Custom Button Card | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| Paper Buttons Row | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Native Tile Cards | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |

## 🚀 Quick Start

**Want the most modern look?**
1. Install **Bubble Card**
2. Replace your light/switch cards
3. Enjoy the iOS-like experience!

**Want a complete redesign?**
1. Install **UI-Lovelace-Minimalist**
2. Follow their blueprint system
3. Get a cohesive, professional dashboard

## 📚 Resources

- **Bubble Card**: https://github.com/nervetattoo/bubble-card
- **UI-Lovelace-Minimalist**: https://github.com/UI-Lovelace-Minimalist/UI
- **Custom Button Card**: https://github.com/custom-cards/button-card
- **Home Assistant Community**: https://community.home-assistant.io/c/dashboards/lovelace-ui

