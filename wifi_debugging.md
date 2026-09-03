# Wi-Fi debugging notes

Home network: Google Nest Wifi, primary router at 192.168.86.1 plus one mesh point.
The Nest sits behind an ISP router at 192.168.20.1 (double NAT).
Mac DNS is manually pinned to 1.1.1.1 and 8.8.8.8 rather than the router.

## Symptom

Connectivity goes bad roughly weekly. A reboot of the primary Nest Wifi point fixes it.

## Diagnosis from 2026-09-03

By the time diagnostics ran, everything passed:

| Check | Result |
|---|---|
| Wi-Fi link (en0, SSID "doofus", ch 36, 5 GHz, 80 MHz) | Associated, -66 dBm, SNR 24-26 dB, tx 650-780 Mbps |
| Gateway 192.168.86.1 ping, 60 packets | 0% loss, avg 8.7 ms |
| 1.1.1.1 ping, 60 packets | 0% loss, avg 20 ms, max 52 ms |
| DNS via 1.1.1.1, 8.8.8.8, and router | All resolve, 21 to 48 ms |
| HTTPS to google, api.anthropic.com, github, claude.ai, npm | All connect, TLS under 130 ms |
| IPv6 | Working, ULA prefix from router only |
| Download from Cloudflare | 52 Mbit/s |
| Traceroute to 1.1.1.1 | 8 hops, clean |
| Proxy or VPN | None |

Timeline from the system log:

- 12:57 Lid closed, machine slept. It had been on a different network (10.33.53.x) since 11:55.
- 13:12, 13:27, 13:35 Dark wakes for Wi-Fi maintenance, a few seconds each. Machine looks offline during these.
- 13:35:34 Lid opened. Auto-join rejoined home Wi-Fi, DHCP gave 192.168.86.72.
- 13:37 to 13:38 Poor link: tx rate stuck at 65 Mbps, about 20% frame retransmits, roughly three neighbour AP beacons for every one of ours. Co-channel interference on channel 36.
- 13:38:32 IPv4 and DNS dropped for 5 seconds, then rebound. No deauth logged, so probably a roam between mesh points.
- 13:39 onward Stable. Tx rate 650 Mbps or more, retransmits about 1%.

Rebooting the primary Nest point later that day fixed the underlying problem. A reboot forces a fresh channel scan.

## Useful commands (macOS)

```sh
# Routes, interfaces, DNS
netstat -rn -f inet
ifconfig en0
scutil --dns | grep nameserver
ipconfig getpacket en0            # DHCP lease details

# Reachability by layer
ping -c 60 -i 0.5 192.168.86.1   # gateway
ping -c 60 -i 0.5 1.1.1.1        # internet
dig @1.1.1.1 google.com
dig @192.168.86.1 google.com
curl -sS -o /dev/null -w 'dns=%{time_namelookup}s connect=%{time_connect}s tls=%{time_appconnect}s http=%{http_code}\n' https://www.google.com/generate_204
traceroute -n -w 1 -q 1 1.1.1.1

# Wi-Fi signal (airport CLI is gone; use system_profiler)
system_profiler SPAirPortDataType | sed -n '/Current Network Information/,/Other Local/p'

# Link quality samples (RSSI, noise, tx rate, retransmits, beacons from other APs)
log show --last 2m --predicate 'process == "airportd"' --style compact | grep 'LQM: rssi'

# When did en0 lose or gain its IPv4 address?
log show --last 12h --predicate 'process == "configd" AND subsystem == "com.apple.SystemConfiguration"' --style compact \
  | grep -E 'network changed: v4\(en0'

# Sleep and wake history
pmset -g log | grep -Ei 'Sleep  |Wake  |DarkWake'
```

Reading the LQM line: `txRetrans` versus `txFrames` gives the retransmit rate. `rxBeaconObss` versus `rxBeaconMbss` shows how many beacons come from other networks on the same channel. High values of both mean the channel is congested.

## Things to try before replacing the Nest Wifi

Roughly in order of payoff.

1. **Scheduled reboot via a smart plug.** Nest Wifi has no reboot schedule. Power-cycle the primary point at 4am every few days. This also forces a fresh channel scan.
2. **Fix the double NAT.** Put the ISP router at 192.168.20.1 into bridge or modem-only mode so the Nest is the sole router. Google Wifi has a history of degrading as its connection tracking table fills. Do not put the Nest into bridge mode instead: that disables mesh and the second point stops working.
3. **Check which point is sick.** Google Home app > Wi-Fi > Points > mesh test. If the point nearest the desk has a weak backhaul, move it closer to the primary.
4. **Turn off IPv6 as an experiment.** Google Home app > Wi-Fi > Settings > Advanced networking > IPv6. Nest Wifi's IPv6 path has recurring reports of leaks and stalls. The ISP only gives a ULA prefix anyway. Give it two weeks.
5. **Look for a chatty client.** ESP32 boards, Matter tooling, and several Google devices are on the LAN. One device stuck in an mDNS or DHCP loop can grind Google Wifi down over days. Check the Home app device list for forgotten boards.
6. **Heat and placement.** Nest Wifi routers throttle and occasionally wedge when warm. Keep it out of cabinets and sun.
7. **Confirm firmware.** Google Home app > Wi-Fi > Settings. The 2019 Nest Wifi units are likely past Google's five-year update window, so no fix is coming from Google.

## If that fails: Ubiquiti

What Nest Wifi cannot do: pick a channel or width, split 2.4 and 5 GHz SSIDs, show client stats, expose logs, schedule reboots, or wire the backhaul on the speaker-style points. Two U6 or U7 APs plus a Cloud Gateway Ultra or Dream Router gets all of that and allows a fixed 5 GHz channel not shared with the neighbours. If the smart plug and double-NAT fix do not reach a month between incidents, switch.
