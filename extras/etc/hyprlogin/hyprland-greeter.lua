-- Hyprland-сессия для hyprlogin (greetd)
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprlogin")
end)

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

hl.config({
    input = {
        kb_layout  = "us,ru",
        kb_options = "grp:alt_shift_toggle",
    },
})