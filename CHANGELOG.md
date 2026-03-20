# CHANGELOG

## 2026-03-19 23:00:00 +03:00
Cause -> Initial project setup request
Change -> Created GorilMail skeleton files and folder layout
Result -> Repository has baseline addon structure

## 2026-03-20 00:57:46 +03:00
Cause -> UI compact list + single-row collect usability pass
Change -> Simplified summary (Inbox Gold only), compact subject text, added per-row collect action, refined visual polish and stable fixed columns
Result -> Faster single-mail collect flow with cleaner compact mailbox list

## 2026-03-20 16:34:33 +03:00
Cause -> Theme system hardening and A/H switch preparation
Change -> Added Horde/Alliance token schema in ui.lua, centralized live theme apply pipeline, added compact session-only A/H toolbar toggle, documented Horde current profile, and kept debug chat noise removed
Result -> UI can switch safely between Horde and Alliance visuals at runtime without changing mailbox/collector behavior

## 2026-03-20 19:40:18 +03:00
Cause -> Mailbox visibility/swap regressions blocked testing flow
Change -> Reviewed lifecycle and swap state path, rolled back regression points (conditional OnMailShow scan gate and unsafe MailFrame show forcing), and narrowed WoW UI toggle issue to CloseMail side-effect in detail cleanup
Result -> Mail visibility blocker is cleared; WoW UI <-> GorilMail swap works again in-session and debugging can continue on remaining non-blocking issues

## 2026-03-20 19:40:58 +03:00
Cause -> Need to preserve root-cause clarity after swap blockage resolution
Change -> Added project note that CloseDefaultMailDetailPanels() must not call CloseMail() because it closes mailbox session root; detail cleanup scope was clarified as detail-only state
Result -> Team now has explicit guidance for future swap fixes: never close default inbox panel during detail cleanup, avoid hidden-but-closed UI state

## 2026-03-20 19:50:50 +03:00
Cause -> Inbox flow stayed stable, then Send mode bootstrap and immediate runtime fix were required
Change -> Added minimal Inbox/Send view switch and initial Send UI (recipient/subject/body/send/clear) in ui.lua, then fixed Send-mode Lua error by correcting SetDetailPanelOpen scope usage and applied small in-style send form spacing/button polish
Result -> Send view opens without runtime error, remains separated from inbox detail behavior, and UI moved to a cleaner productized baseline for next controlled iteration

## 2026-03-20 20:38:45 +03:00
Cause -> WoW UI -> GorilMail swap-back path remained unstable after interaction masking fixes
Change -> Stabilized the Blizzard-side GorilMail return button path in ui.lua (reliable click layer + swap-back callback alignment), and fixed `SetStatusText` nil scope issue via forward-local binding
Result -> GorilMail <-> WoW UI roundtrip is responsive again in-session, and swap-back callback no longer throws runtime error

## 2026-03-20 21:52:04 +03:00
Cause -> Detail preview usability pass required final stabilization on list/detail interactions and tooltip behavior
Change -> Refined ui.lua with targeted fixes: corrected item bind order in detail preview, converted icon border overlay to real border rendering, stabilized icon-only tooltip lifecycle/anchor/compare suppression, polished toolbar button order/spacing, and fixed scroll-preserved selection so detail panel no longer collapses on visible-row changes
Result -> Item preview is readable and stable (icon, quality, tooltip), toolbar actions are cleaner to use, and detail panel stays pinned to the selected mail during scroll without unintended close/switch


## 2026-03-20 23:01:39 +03:00
Cause -> Ghost Blizzard MailFrame UIPanel/layout offset persisted while GorilMail mode was active
Change -> In ui.lua, added MailFrame UIPanelWindows bookkeeping stash/restore (`UIPanelWindows["MailFrame"]`) tied to mode transitions and restore paths; GorilMail mode now temporarily removes MailFrame managed-panel registration, WoW UI/restore paths bring it back
Result -> MailFrame no longer stays managed in GorilMail mode, reducing ghost panel-layout side effects while preserving swap/restore behavior
