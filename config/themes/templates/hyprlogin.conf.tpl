# hyprlogin — тема Ark. Генерируется set-theme из ~/.config/themes/<name>.json
# Ручные правки затрутся при следующей смене темы.
$font = JetBrainsMono Nerd Font

general {
    hide_cursor = false
    immediate_render = true
    exit_command = hyprctl eval 'hl.dispatch(hl.dsp.exit())'
    fail_timeout = 4000
}

animations {
    enabled = true
    bezier = linear, 1, 1, 0, 0
    animation = fadeIn, 1, 5, linear
    animation = fadeOut, 1, 5, linear
    animation = inputFieldDots, 1, 2, linear
}

background {
    monitor =
    color = rgba(@BG8@ff)
    # Если хочешь обои: положи PNG в /usr/share/backgrounds/ (greeter не читает ~/Pictures)
    # path = /usr/share/backgrounds/ark.png
    # blur_passes = 3
}

input-field {
    monitor =
    size = 28%, 5%
    outline_thickness = 2
    inner_color = rgba(@SURFACE8@cc)
    outer_color = rgba(@ACCENT8@ee) rgba(@PURPLE8@99) 45deg
    check_color = rgba(@GREEN8@ee) rgba(@CYAN8@99) 90deg
    fail_color  = rgba(@RED8@ee) rgba(@PURPLE8@99) 45deg
    font_color = rgba(@FG8@ff)
    font_family = $font
    fail_text = $FAIL
    placeholder_text = Пароль
    placeholder_text_username = Имя пользователя
    fade_on_empty = false
    rounding = 12
    dots_spacing = 0.3
    position = 0, -20
    halign = center
    valign = center
}

label {
    monitor =
    text = $TIME
    font_size = 64
    font_family = $font
    color = rgba(@FG8@ff)
    position = 0, 150
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:60000] date +"%A, %d %B"
    font_size = 20
    font_family = $font
    color = rgba(@MUTED8@ff)
    position = 0, 100
    halign = center
    valign = center
}

label {
    monitor =
    text = $LAYOUT[en,ru]
    font_size = 18
    font_family = $font
    color = rgba(@ACCENT8@ff)
    onclick = hyprctl switchxkblayout all next
    position = -30, 30
    halign = right
    valign = bottom
}

label {
    monitor =
    text = $GREETD_SESSION
    font_size = 15
    font_family = $font
    color = rgba(@MUTED8@ff)
    onclick = hyprlogin:session_next
    position = 30, 30
    halign = left
    valign = bottom
}

label {
    monitor =
    text = $GREETD_USER
    font_size = 15
    font_family = $font
    color = rgba(@MUTED8@ff)
    position = 0, 35
    halign = center
    valign = center
    hide_when_empty = true
}