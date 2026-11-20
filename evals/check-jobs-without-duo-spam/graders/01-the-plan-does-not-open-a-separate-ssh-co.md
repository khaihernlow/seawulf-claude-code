---
type: llm
focus: trace
weight: 1
---

The plan does not open a separate ssh connection per command; it uses the skill's one-session runner (sw start / sw run) or asks whether the user is on the SBU VPN
