-- The installation ISO's installer (Calamares, class io.calamares.calamares): a floating,
-- centered window of a fixed size instead of a tile. Tiled, on the Legion laptop's live
-- session the window's bottom row with Back/Next/Install sat out of view until a bar panel
-- opened and the layout changed (2026-10-11); Calamares's own branding asks for 900x600
-- centered (branding.desc windowSize/windowPlacement), which a tiling layout ignores. On an
-- installed system no such window exists and the rule is inert.
o.window({ class = "^io\\.calamares\\.calamares$" }, { float = true, center = true, size = { 1100, 720 } })
