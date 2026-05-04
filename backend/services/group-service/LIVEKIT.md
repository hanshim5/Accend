# Self-hosted LiveKit (voice)

The group-service endpoint `POST /voice/livekit/token` mints JWTs for the official [LiveKit server](https://docs.livekit.io/home/self-hosting/deployment/).

## Where to put the API key and secret

Put them **only on the machine/process that runs group-service**, as environment variables. The Flutter app and api-gateway **never** store these; they only receive short-lived tokens from group-service.

**Recommended (local dev):** put LiveKit variables in either place (group-service loads **both**, in this order: `backend/.env` first, then `group-service/.env` overrides):

1. **`backend/.env`** (shared with other services), or  
2. **`backend/services/group-service/.env`** (service-only)

`app/config.py` resolves these paths from the file location, not from the shell’s current directory—so `uvicorn` can be started from any folder and `LIVEKIT_*` in `backend/.env` still applies.

Example:

```env
LIVEKIT_API_KEY=APIxxxxxxxx
LIVEKIT_API_SECRET=<paste the secret from LiveKit>
LIVEKIT_PUBLIC_WS_URL=ws://localhost:7880
```

Add `.env` to `.gitignore` if it isn’t already so keys are not committed.

**If you run group-service in Docker:** pass the same three variables in that service’s `environment:` or `env_file:` in compose—do not put secrets in the Flutter app.

| Variable | Example | Purpose |
|----------|---------|---------|
| `LIVEKIT_API_KEY` | `APIxxxxxxxx` | From `livekit-server --keys` or container logs |
| `LIVEKIT_API_SECRET` | long secret | Must match the running LiveKit server |
| `LIVEKIT_PUBLIC_WS_URL` | `ws://localhost:7880` | WebSocket URL **clients** use to connect |
| `LIVEKIT_URL` | (same as above) | **Alias** for `LIVEKIT_PUBLIC_WS_URL` if your `.env` uses the shorter name |

Use either **`LIVEKIT_PUBLIC_WS_URL`** or **`LIVEKIT_URL`** for the WebSocket URL (same value).

**Important:** That URL must be reachable from the phone/emulator:

- **Android emulator → dev machine:** often `ws://10.0.2.2:7880`
- **Physical device on LAN:** `ws://<your-PC-LAN-IP>:7880`
- **TLS in production:** `wss://livekit.yourdomain.com`

## Quick local server (Docker)

```bash
docker run --rm -it -p 7880:7880 -p 7881:7881/udp -p 7882:7882/udp livekit/livekit-server --dev --bind 0.0.0.0
```

Copy the printed **API Key** and **API Secret** into `group-service` `.env` as `LIVEKIT_API_KEY` and `LIVEKIT_API_SECRET`. Use `LIVEKIT_PUBLIC_WS_URL=ws://localhost:7880` for desktop Flutter; adjust for emulator/device as above.

Production deployments should use a proper config file, TLS, and [TURN](https://docs.livekit.io/home/self-hosting/ports-firewall/) (e.g. coturn) for restrictive networks.
