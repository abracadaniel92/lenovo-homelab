# Hisense TV MQTT Bridge - Troubleshooting Guide

## Problem: "Unknown Error" when adding Hisense TV integration

**Root Cause**: MQTT broker not configured in Home Assistant.

## Solution Steps

### Step 1: MQTT Broker (Mosquitto) is Now Running ✅

The MQTT broker has been set up and started:
- **Location**: `/home/docker-projects/mosquitto/`
- **Port**: 1883
- **Status**: Running

### Step 2: Configure MQTT in Home Assistant

1. Open Home Assistant: `http://localhost:8123` (or `http://192.168.1.97:8123`)

2. Go to **Settings** → **Devices & Services** → **Add Integration**

3. Search for **"MQTT"** and click it

4. Configure MQTT connection:
   - **Broker**: `localhost` (or `192.168.1.97` if accessing from another device)
   - **Port**: `1883`
   - **Username**: Leave blank (anonymous access enabled)
   - **Password**: Leave blank
   - Click **Submit**

5. You should see "MQTT has been set up successfully" ✅

### Step 3: Add Hisense TV Integration

1. In Home Assistant, go to **Settings** → **Devices & Services** → **Add Integration**

2. Search for **"Hisense TV"** (or **"Hisense"**)

3. Follow the setup wizard:
   - Enter your TV's **IP address** (find it using the `find-tv-device.sh` script)
   - The integration will automatically discover the TV if it's on the network

4. If you still get errors:
   - Make sure the TV is **turned on**
   - Ensure the TV is on the **same network** as Home Assistant
   - Check the TV's IP address is correct

### Step 4: Verify MQTT Connection

To verify MQTT is working:

1. Go to **Developer Tools** → **MQTT**

2. Try subscribing to a test topic:
   - **Topic**: `test/topic`
   - Click **Listen**

3. Try publishing a message:
   - **Topic**: `test/topic`
   - **Payload**: `Hello MQTT`
   - Click **Publish**

If you see the message appear in the listener, MQTT is working correctly! ✅

## Common Issues

### Issue: "Cannot subscribe to topic" error

**Solution**: Make sure MQTT integration is configured in Home Assistant before adding the Hisense TV integration.

### Issue: TV not found

**Solutions**:
- Ensure TV is powered on
- Check TV and Home Assistant are on the same network
- Verify TV's IP address (use `find-tv-device.sh` script)
- Try restarting Home Assistant: `docker compose restart` in `/home/docker-projects/homeassistant`

### Issue: MQTT connection fails

**Solutions**:
- Verify Mosquitto is running: `docker ps | grep mosquitto`
- Check Mosquitto logs: `cd /home/docker-projects/mosquitto && docker compose logs`
- Ensure Home Assistant can reach `localhost:1883` (they're both on host network, so this should work)

### Issue: Integration stuck loading / not activating

**Root Cause**: The Hisense TV has its own MQTT broker on port 36669. Mosquitto needs to bridge to it.

**Solution Steps**:

1. **Find your TV's IP address**:
   ```bash
   bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/find-tv-device.sh"
   ```
   Or check on the TV: Settings → Network → Network Status

2. **Configure the bridge**:
   - Edit `/home/docker-projects/mosquitto/config/mosquitto.conf`
   - Replace `TV_IP_HERE` with your TV's actual IP address
   - Example: `address 192.168.1.100:36669`

3. **Restart Mosquitto**:
   ```bash
   cd /home/docker-projects/mosquitto
   docker compose restart
   ```

4. **Check bridge connection**:
   ```bash
   docker compose logs -f mosquitto | grep -i bridge
   ```
   You should see messages about the bridge connecting.

5. **Verify TV is ready**:
   - TV must be **turned on**
   - TV must be on the **same network**
   - Some TVs may show a pairing prompt - accept it

6. **Retry the integration**:
   - Go back to Home Assistant
   - Remove the stuck integration (if possible)
   - Add it again

**Important Notes**:
- The TV uses port **36669** for MQTT (not 1883)
- Default credentials: username `hisenseservice`, password `multimqttservice`
- The bridge uses `bridge_insecure true` - some TVs may require TLS certificates
- If bridge still fails, check if your TV model supports MQTT (some Vidaa OS versions don't)

## MQTT Broker Management

```bash
# Start Mosquitto
cd /home/docker-projects/mosquitto
docker compose --profile utilities up -d

# Stop Mosquitto
docker compose down

# View logs
docker compose logs -f

# Restart
docker compose restart
```

## Files Created

- `/home/docker-projects/mosquitto/docker-compose.yml` - Mosquitto container config
- `/home/docker-projects/mosquitto/config/mosquitto.conf` - MQTT broker configuration
- `/home/docker-projects/mosquitto/README.md` - Mosquitto setup guide

## Next Steps

After MQTT is configured in Home Assistant:
1. ✅ MQTT integration added successfully
2. Add Hisense TV integration
3. Configure TV automations if needed

## Related Files

- `INTEGRATION_SUMMARY.md` - Lists all Home Assistant integrations
- `README.md` - General Home Assistant setup

