# GorilMail

GorilMail is a standalone World of Warcraft Retail mailbox addon by **Goril Labs**.

Status:
- Proprietary product
- **All Rights Reserved**

## Scope
- Mailbox-focused only
- Event-driven, queue-based collect flow
- COD-safe defaults
- No external dependencies
- No Auction House features

## Features
- Inbox list view with sender, subject, money, COD, attachment indicators
- `Collect All` with paced step processing and post-update validation
- Single-row collect from inbox list
- Send view with recipient/subject/body + attachments + COD/Gold fields
- Fill Similar flow for send attachments
- Session-level collect summary in UI/chat
- Separate Destroy panel flow (manual secure action model)
- Destroy candidate scan (Disenchant / Milling), `Destroy Next`, `Skip`, refresh, selectable rows

## Commands
- `/gorilmail destroy` -> toggle Destroy panel
- `/gmail destroy` -> toggle Destroy panel

## Usage
- Open any mailbox NPC to open GorilMail mailbox UI.
- Use toolbar to switch between Inbox / Send.
- Use Destroy commands above to open the Destroy panel.

## Requirements
- World of Warcraft Retail
- Interface: `120001`

## Installation
1. Copy `GorilMail` folder into `_retail_/Interface/AddOns/`
2. Restart game or run `/reload`
3. Enable `GorilMail` in AddOns list

## License
This software is proprietary and provided under **All Rights Reserved** by **Goril Labs**.

See [LICENSE](LICENSE).
