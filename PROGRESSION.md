# PROGRESSION

## 2026-03-19 23:00:00 +03:00
Cause -> New addon bootstrap
Change -> Added initial documentation and Lua file skeletons
Result -> Ready for first implementation step

## 2026-03-20 00:57:46 +03:00
Cause -> Improve mailbox panel usability without backend refactor
Change -> Kept existing collect flows, added lightweight row action and compact subject rendering, removed Session Total from UI
Result -> Panel is more compact and practical for single or bulk collect usage

## 2026-03-20 16:34:33 +03:00
Cause -> Move from single-theme implementation to toggle-ready architecture
Change -> Introduced shared theme tokens, added Alliance token set alongside Horde, implemented safe in-session A/H toolbar toggle with full repaint path, and preserved non-theme behavior paths
Result -> Theme switching foundation is complete and stable for next-step persistence work

## 2026-03-20 19:40:18 +03:00
Cause -> Critical runtime blocker: mailbox list visibility and WoW UI swap instability
Change -> Ran targeted regression isolation on lifecycle/swap path, reverted the two high-impact regressors, and finalized a narrow WoW UI toggle fix by removing CloseMail side-effect from default detail cleanup
Result -> Blocking "mail not visible" issue is effectively passed; addon returned to a usable state for continued polish and controlled follow-up fixes

## 2026-03-20 19:40:58 +03:00
Cause -> Prevent repeat of resolved mail swap blockage
Change -> Recorded explicit working assumption: detail cleanup must never close mailbox root UI; CloseMail in detail cleanup path identified as primary trigger for delayed/hidden swap confusion
Result -> Regression memory is formalized; future lifecycle patches can target detail-only cleanup without reintroducing swap breakage

## 2026-03-20 19:50:50 +03:00
Cause -> Product flow expanded to include outbound mail draft UI while preserving existing inbox lifecycle
Change -> Implemented a minimal Send view inside GorilMail (mode switch + form controls), then resolved the Send transition crash (`SetDetailPanelOpen` nil call) with a narrow scope fix and refined form alignment within current theme language
Result -> Current state is stable for Inbox/Send mode transitions, no Send-mode Lua error, and ready for focused send-behavior hookup in a later patch

## 2026-03-20 20:38:45 +03:00
Cause -> Post-fix validation still showed broken swap-back path from Blizzard UI and a callback scope runtime error
Change -> Narrowly corrected ui.lua return-button click path for repeated WoW UI <-> GorilMail switching, improved click reliability on Blizzard-side return control, and bound `SetStatusText` correctly in local scope
Result -> Current blocker is passed: return button responds, swap-back works in repeated cycles, and nil-call crash on status update is removed

## 2026-03-20 21:52:04 +03:00
Cause -> Iterative QA revealed remaining polish blockers in detail tooltip flow and scroll-linked selection persistence
Change -> Applied focused ui.lua hardening for detail item preview (bind-order correctness, non-blocking quality border, icon-anchored tooltip with compare suppression and icon-only hover scope), improved top toolbar control order/spacing, and corrected selection persistence logic so scroll no longer drops detail state when selected mail remains in dataset
Result -> Detail panel and inbox list now behave consistently under rapid interaction; tooltip noise is controlled and selection stays stable during scroll while existing mailbox workflows remain intact


## 2026-03-20 23:01:39 +03:00
Cause -> QA still observed ghost UIPanel positioning as if Blizzard MailFrame remained active behind GorilMail
Change -> Applied focused ui.lua panel-bookkeeping update: stash/remove `UIPanelWindows["MailFrame"]` in GorilMail mode and restore it in WoW UI/OnHide/OnMailClosed paths, while keeping existing interaction and swap flows intact
Result -> Progress moved from interaction masking to managed-panel state control; expected outcome is cleaner coexistence with other UIPanel windows without reintroducing prior swap regressions
