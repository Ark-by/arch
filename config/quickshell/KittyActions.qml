pragma Singleton
import QtQuick
import Quickshell

// Наиболее употребимые действия kitty (map <key> <action>).
Singleton {
    readonly property var actions: [
        "new_tab", "new_tab_with_cwd", "close_tab", "next_tab", "previous_tab",
        "move_tab_forward", "move_tab_backward", "goto_tab 1", "goto_tab 2", "goto_tab 3",
        "new_window", "new_window_with_cwd", "close_window", "close_other_windows_in_tab",
        "next_window", "previous_window", "move_window_forward", "move_window_backward",
        "move_window_to_top", "swap_with_next_window", "swap_with_previous_window",
        "first_window", "second_window", "third_window", "fourth_window", "fifth_window",
        "sixth_window", "seventh_window", "eighth_window", "ninth_window", "tenth_window",
        "neighboring_window left", "neighboring_window right", "neighboring_window up", "neighboring_window down",
        "left", "right", "up", "down",
        "scroll_line_up", "scroll_line_down", "scroll_page_up", "scroll_page_down",
        "scroll_home", "scroll_end", "scroll_to_prompt",
        "show_scrollback", "show_last_command_output", "show_hyperlink_target",
        "toggle_layout", "select_all",
        "copy_to_clipboard", "copy_and_clear_or_interrupt", "paste_from_clipboard", "paste_from_selection",
        "open_url_with_hints", "insert_text", "pass_selection_to_program",
        "send_text all", "send_key all", "combine",
        "launch", "kbd_mode", "debug_config", "edit_config_file",
        "reset_terminal", "clear_terminal",
        "increase_font_size", "decrease_font_size", "reset_font_size",
        "toggle_fullscreen_layout", "search"
    ]
}