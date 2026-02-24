# TODO Done — Sprint 3: Detail Face (2026-02-23)

- [x] **S3-1: Update DesignTokens.swift — equalize bezel gaps + tick mark tokens** — ringInset 4→5, bezelGap 2→1, ring radius 10→9, tickLength 4→6, tickWidth 1.5→2. `c481cd1`
- [x] **S3-2: Fix MinuteBezelView tick marks — white, larger, always visible on top of fill** — All 4 cardinal ticks now .white, removed conditional gold/gray logic. `b73ff73`
- [x] **S3-3: Restructure ClockView — persistent ring layer, face-dependent opacity, animated transitions, onReplay routing** — MinuteBezelView extracted to persistent background, ring opacity per face, animated transitions, InfoPanelView gains onReplay. `6251f69`
- [x] **S3-4: Rewrite InfoPanelView body as Detail face layout** — 28pt header (chevron + gear), 196×196 board with CTA overlay, PlayerNameFormatter names, event line, removed Round/AM-PM/labels. `d31b00a`
