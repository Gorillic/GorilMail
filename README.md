# GorilMail

GorilMail is a standalone World of Warcraft Retail mailbox addon focused on fast inbox handling and safer bulk collection behavior.

It is built around a minimal, event-driven architecture:
- scan inbox rows,
- prepare a collect queue,
- process one step at a time,
- validate outcomes before advancing,
- keep COD-safe behavior by default.

## Features
- Compact inbox listing (sender, subject, money, COD, attachment state)
- Collect All flow with queue + pending-command pacing
- Per-step validation after inbox updates (event-driven progression)
- COD-aware blocking by default
- Session-level result snapshot and diagnostics telemetry
- In-game telemetry dump command for troubleshooting

## Requirements
- World of Warcraft Retail
- Interface version: `120001`

## Installation
1. Copy the `GorilMail` folder into:
   - `_retail_/Interface/AddOns/`
2. Restart the game or run `/reload`.
3. Ensure `GorilMail` is enabled in the AddOns list.

## Usage
- Open any mailbox NPC to open GorilMail.
- Click `Collect All` to start queue-based collection.
- Use `Refresh` to re-scan inbox rows.
- Switch between `Inbox` and `Send` modes from the toolbar.

Slash commands:
- `/gorilmail` -> toggle GorilMail panel
- `/gmtelemetry` or `/gmtel` -> dump current collector session snapshot (debug/diagnostic)

## How Collect All Works
High-level flow:
1. Prepare collectable rows from current mailbox snapshot.
2. Build queue entries with row fingerprint/identity metadata.
3. Issue one action at a time (`TakeInboxMoney` / `AutoLootMailItem`).
4. Wait for update events and re-scan inbox rows.
5. Validate action outcome.
6. Advance queue only after outcome is resolved.

Safety mechanisms:
- Command pending guard (`C_Mail.IsCommandPending()`)
- Deferred settle checks for transient timing issues
- Ambiguity-safe identity matching (avoid unsafe forced row binds)
- Explicit skip reasons and close telemetry in session snapshot

## Session Snapshot / Diagnostics
Collector snapshot includes:
- final outcome counts,
- skip reason distribution (`skipReasonCounts`),
- last skip reason (`lastSkipReason`),
- close source telemetry (`closeTelemetry`).

Close telemetry currently tracks:
- `source` (`event_mail_closed`, `mailframe_onhide`, `core_handle_mail_closed`)
- `mailboxOpen`
- `mailFrameShown`
- `collectActive`

## Architecture
Core files:
- `core.lua` -> global mailbox lifecycle/event wiring
- `mailbox.lua` -> inbox scanning and normalized row model
- `collector.lua` -> Collect All queue, validation, recovery, telemetry
- `ui.lua` -> panel, controls, rendering (helper-based structure)
- `utils.lua` -> print/misc helpers

## Non-Goals
- No external dependencies/libraries
- No Auction House workflows
- No broad automation outside mailbox scope

## Development Notes
- The addon prioritizes behavior safety and deterministic progression over raw speed.
- UI polish is intentionally kept separate from collector behavior hardening.

## License
This project is proprietary and licensed under **All Rights Reserved** by **Goril Labs**.

See [LICENSE](LICENSE) for details.
