# Hisense TV Integration Stuck Loading - Fix Guide

## Problem
Integration gets stuck in "loading" loop and never completes.

## Root Causes Found

1. **MQTT Bridge Not Connected**: Mosquitto bridge to TV (port 36669) may not be establishing connection
2. **Home Assistant MQTT Connection Lost**: When Mosquitto restarts, HA loses MQTT connection
3. **No Messages from TV**: Integration waits for MQTT messages that never arrive
4. **TV Not Responding**: TV's MQTT broker might require pairing/acceptance

## Solutions to Try

### Step 1: Verify TV IP is Correct

```bash
# Check TV is reachable
ping -c 2 192.168.1.218

# Check MQTT port is open
timeout 3 bash -c "echo > /dev/tcp/192.168.1.218/36669" && echo "Port OPEN" || echo "Port CLOSED"
```

### Step 2: Check Bridge Connection

```bash
cd /home/docker-projects/mosquitto
docker compose logs -f mosquitto | grep -i bridge
```

Look for:
- ✅ "Bridge connected" or connection success messages
- ❌ "Error resolving bridge address" or connection failures

### Step 3: Verify TV MQTT Settings

**On the TV:**
1. Make sure TV is **powered on**
2. Settings → Network → Check network connection
3. Some Vidaa OS versions require enabling "Developer Mode" or "MQTT Service"
4. Check if TV shows any pairing/connection prompts

### Step 4: Test MQTT Connectivity Directly

```bash
# Test subscribing to TV's MQTT topics (if TV supports direct connection)
mosquitto_sub -h 192.168.1.218 -p 36669 -u hisenseservice -P multimqttservice -t '#' -v
```

If this works, you'll see messages from the TV.

### Step 5: Check Bridge Config

Verify `/home/docker-projects/mosquitto/config/mosquitto.conf` has:

```
connection hisense_tv
address 192.168.1.218:36669
username hisenseservice
password multimqttservice
clientid HomeAssistant
bridge_insecure true
```

### Step 6: Restart Everything in Order

```bash
# 1. Restart Mosquitto
cd /home/docker-projects/mosquitto
docker compose restart mosquitto

# 2. Wait for bridge to connect (check logs)
docker compose logs -f mosquitto | grep -i bridge

# 3. Restart Home Assistant
cd /home/docker-projects/homeassistant
docker compose restart homeassistant

# 4. Wait 30-60 seconds for HA to reconnect to MQTT
```

### Step 7: Cancel and Retry Integration

1. **Cancel the stuck integration**:
   - Go to Home Assistant UI
   - Settings → Devices & Services
   - Find the stuck "Hisense TV" entry
   - Click the 3 dots → Delete/Remove

2. **Clear any partial config** (if needed):
   ```bash
   # Check for partial config files
   find /home/docker-projects/homeassistant/config -name "*hisense*" -type f
   ```

3. **Retry adding integration**:
   - Make sure TV is ON
   - Make sure bridge is connected (check Mosquitto logs)
   - Make sure HA is connected to MQTT (check HA logs)

## Debugging Steps

### Check if Bridge is Connected

```bash
docker compose -f /home/docker-projects/mosquitto/docker-compose.yml logs mosquitto | grep -i "bridge.*connect"
```

### Check if Messages are Flowing

```bash
# Subscribe to hisense topics through Mosquitto
docker exec mosquitto mosquitto_sub -h localhost -t 'hisense/#' -v
```

If you see messages, the bridge is working.

### Check Home Assistant MQTT Connection

In Home Assistant:
- Settings → Devices & Services → MQTT
- Should show "Connected" status
- If not, click "Configure" and reconnect

### Monitor Integration Setup

```bash
cd /home/docker-projects/homeassistant
docker compose logs -f homeassistant | grep -i hisense
```

Watch for errors during setup.

## Common Issues

### Issue: "async_show_progress" warning

This is a known issue with the custom integration. It waits indefinitely for TV response. Solution: Ensure TV is responding on MQTT.

### Issue: Bridge shows "using insecure mode" but no connection

- TV might require TLS certificates
- TV might need pairing/acceptance first
- Check TV's network and MQTT service settings

### Issue: No messages on hisense topics

- Bridge might not be connected
- TV might not be sending messages
- Topic pattern might be wrong for your TV model
- Check TV model compatibility with this integration

## Alternative: Try Direct MQTT Connection

Some Hisense TV integrations work without a bridge. Check if your integration supports direct connection to TV's MQTT broker instead of using Mosquitto bridge.

## TV Model Compatibility

This integration works best with:
- Vidaa OS 5.0+
- TVs with MQTT service enabled
- Some models require enabling "Remote App" or "Smart Home" features

Check the integration's GitHub page for your specific TV model compatibility.


