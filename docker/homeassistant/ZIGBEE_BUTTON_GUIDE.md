# Zigbee Smart Button Automation Guide

## What You Need

### 1. Zigbee Coordinator (USB Stick)
You need a Zigbee USB coordinator to connect Zigbee devices to Home Assistant. Popular options:

**Recommended:**
- **Sonoff Zigbee 3.0 USB Dongle Plus** (~$15-20)
  - Best value, widely supported
  - Works with Zigbee2MQTT and ZHA
- **ConBee II / RaspBee II** (~$40-50)
  - Very reliable, good range
- **CC2652P2 based sticks** (various brands)
  - Excellent range and performance

### 2. Zigbee Smart Button
Popular options:
- **Aqara Smart Button** (~$10-15)
  - Single, double, long press support
  - Very reliable
- **IKEA TRÅDFRI Button** (~$8-12)
  - Simple, reliable
- **Philips Hue Dimmer Switch** (~$20)
  - Multiple buttons, more options
- **Sonoff Button** (~$8-10)
  - Good value

## Setup Steps

### Step 1: Install Zigbee Coordinator

#### Option A: Zigbee2MQTT (Recommended - More Features)
1. Install Zigbee2MQTT as a separate container
2. Connect coordinator USB stick
3. Configure in Home Assistant

#### Option B: ZHA (Built-in - Simpler)
1. Connect coordinator USB stick
2. Add integration in Home Assistant UI
3. No separate container needed

### Step 2: Pair the Button
1. Put button in pairing mode (usually hold button for 5-10 seconds)
2. In Home Assistant: Settings → Devices & Services → Add Device
3. Button should appear and pair

### Step 3: Create Automations

## Automation Examples

### Single Press: Turn All Devices ON

```yaml
alias: "Button - All Devices ON"
description: "Turn on all devices with single button press"
trigger:
  - platform: device
    domain: zha  # or mqtt if using Zigbee2MQTT
    device_id: YOUR_BUTTON_DEVICE_ID
    type: button_short_press
    subtype: button_1
condition: []
action:
  - service: homeassistant.turn_on
    target:
      entity_id:
        - light.living_room
        - light.bedroom
        - switch.fan
        - switch.heater
        # Add all your devices here
  - service: notify.mobile_app_your_phone
    data:
      message: "All devices turned ON"
mode: single
```

### Double Press: Turn All Devices OFF

```yaml
alias: "Button - All Devices OFF"
description: "Turn off all devices with double button press"
trigger:
  - platform: device
    domain: zha  # or mqtt if using Zigbee2MQTT
    device_id: YOUR_BUTTON_DEVICE_ID
    type: button_double_press
    subtype: button_1
condition: []
action:
  - service: homeassistant.turn_off
    target:
      entity_id:
        - light.living_room
        - light.bedroom
        - switch.fan
        - switch.heater
        # Add all your devices here
  - service: notify.mobile_app_your_phone
    data:
      message: "All devices turned OFF"
mode: single
```

### Advanced: Group-Based Control

Instead of listing all devices, use groups:

```yaml
# In configuration.yaml
group:
  all_lights:
    name: All Lights
    entities:
      - light.living_room
      - light.bedroom
      - light.kitchen
  all_switches:
    name: All Switches
    entities:
      - switch.fan
      - switch.heater
```

Then in automation:
```yaml
action:
  - service: homeassistant.turn_on
    target:
      entity_id:
        - group.all_lights
        - group.all_switches
```

## Quick Setup Commands

### Find Your USB Zigbee Coordinator
```bash
# List USB devices
lsusb

# Check if it's detected
ls -la /dev/ttyUSB* /dev/ttyACM*
```

### If Using Zigbee2MQTT
```bash
# Add to docker-compose.yml or create separate container
# See: https://www.zigbee2mqtt.io/guide/installation/docker.html
```

## Recommended Setup

1. **Buy**: Sonoff Zigbee 3.0 USB Dongle Plus + Aqara Smart Button
2. **Install**: Zigbee2MQTT (more features, better device support)
3. **Pair**: Button via Zigbee2MQTT UI
4. **Create**: Automations in Home Assistant UI (easier than YAML)

## Tips

- Place Zigbee coordinator centrally for best range
- Use USB extension cable to avoid interference
- Some buttons support long press (hold) - you can add more actions!
- Test automations before relying on them
- Use Home Assistant UI for automations (Settings → Automations) - it's easier than YAML

