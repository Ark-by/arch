{
  "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
  "name": "Ark @TITLE@",
  "author": "Ark-by (based on Tokyo Night by Folke / ssaunderss Zed port)",
  "themes": [
    {
      "name": "Ark @TITLE@",
      "appearance": "dark",
      "style": {
        "accents": [
          "@ANSI5@66",
          "@ACCENT@66",
          "@ANSI2@66",
          "@TEAL@66",
          "@ANSI3@66",
          "@ORANGE@66",
          "@ANSI1@66"
        ],
        "background": "@ZED_BG@",
        "background.appearance": "transparent",
        "border": "@BORDER_DARK@",
        "border.disabled": "@BORDER_DARK@",
        "border.focused": "#545c7e33",
        "border.selected": "@BORDER_DARK@",
        "border.transparent": "@BORDER_DARK@",
        "border.variant": "@BORDER_DARK@",
        "conflict": "@ANSI5@",
        "conflict.background": "@BG@",
        "conflict.border": "@ANSI8@",
        "created": "@ANSI2@",
        "created.background": "@BG@",
        "created.border": "@ANSI8@",
        "deleted": "@ANSI1@",
        "deleted.background": "@BG@",
        "deleted.border": "@ANSI8@",
        "drop_target.background": "@BG2@",
        "editor.active_line.background": "#00000000",
        "editor.active_line_number": "@ANSI7@",
        "editor.active_wrap_guide": "@BORDER_DARK@",
        "editor.background": "#00000000",
        "editor.document_highlight.bracket_background": "@ANSI8@",
        "editor.document_highlight.read_background": "@HIGHLIGHT@",
        "editor.document_highlight.write_background": "@HIGHLIGHT@",
        "editor.foreground": "@FG@",
        "editor.gutter.background": "#00000000",
        "editor.highlighted_line.background": null,
        "editor.indent_guide": "@HIGHLIGHT@",
        "editor.indent_guide_active": "@MUTED@",
        "editor.invisible": null,
        "editor.line_number": "@ANSI8@",
        "editor.subheader.background": "@ZED_BG@",
        "editor.wrap_guide": "@BORDER_DARK@",
        "element.active": "@BG3@",
        "element.background": "@ZED_BG@",
        "element.disabled": "@ANSI8@",
        "element.hover": "@MUTED@",
        "element.selected": "@MUTED@",
        "elevated_surface.background": "@ELEVATED@",
        "error": "@ANSI1@",
        "error.background": "@BG@",
        "error.border": "@ANSI8@",
        "ghost_element.active": "@BG3@",
        "ghost_element.background": "#00000000",
        "ghost_element.disabled": "@ANSI8@",
        "ghost_element.hover": "@MUTED@",
        "ghost_element.selected": "@MUTED@",
        "hidden": "@MUTED@",
        "hidden.background": "@BG@",
        "hidden.border": "@ANSI8@",
        "hint": "@MUTED2@",
        "hint.background": "@BG@",
        "hint.border": "@ANSI8@",
        "icon": "@ANSI7@",
        "icon.accent": "@ANSI6@",
        "icon.disabled": "@ANSI8@",
        "icon.muted": "@ANSI7@",
        "icon.placeholder": "@MUTED@",
        "ignored": "@MUTED2@",
        "ignored.background": "@BG@",
        "ignored.border": "@ANSI8@",
        "info": "#0da0ba",
        "info.background": "@BG@",
        "info.border": "@ANSI8@",
        "link_text.hover": "@ANSI6@",
        "modified": "@ANSI3@",
        "modified.background": "@BG@",
        "modified.border": "@ANSI8@",
        "pane.focused_border": null,
        "pane_group.border": "@BORDER_DARK@",
        "panel.background": "#00000000",
        "panel.focused_border": null,
        "panel.indent_guide": "@HIGHLIGHT@",
        "panel.indent_guide_active": "@MUTED@",
        "panel.indent_guide_hover": "@MUTED@",
        "panel.overlay_background": "@ELEVATED@",
        "predictive": "@MUTED2@",
        "predictive.background": "@BG@",
        "predictive.border": "@ANSI8@",
        "renamed": "@ANSI2@",
        "renamed.background": "@BG@",
        "renamed.border": "@ANSI8@",
        "scrollbar.thumb.background": "@ANSI8@80",
        "scrollbar.thumb.border": "@ANSI8@",
        "scrollbar.thumb.hover_background": "@ANSI8@",
        "scrollbar.track.background": "@BG@80",
        "scrollbar.track.border": "@BORDER_DARK@",
        "search.match_background": "@ANSI8@",
        "status_bar.background": "@ZED_BG@",
        "success": "@ANSI2@",
        "success.background": "@BG@",
        "success.border": "@ANSI8@",
        "surface.background": "@ZED_BG@",
        "syntax": {
          "attribute": {
            "color": "@ANSI5@"
          },
          "boolean": {
            "color": "@ORANGE@"
          },
          "comment": {
            "color": "@MUTED@",
            "font_style": "italic"
          },
          "comment.doc": {
            "color": "@MUTED@",
            "font_style": "italic"
          },
          "constant": {
            "color": "@ORANGE@"
          },
          "constructor": {
            "color": "@ANSI1@"
          },
          "embedded": {
            "color": "@FG@"
          },
          "emphasis": {
            "color": "@ANSI1@",
            "font_style": "italic"
          },
          "emphasis.strong": {
            "color": "@ANSI1@",
            "font_weight": 700
          },
          "enum": {
            "color": "@CYAN_DARK@"
          },
          "function": {
            "color": "@ACCENT@"
          },
          "hint": {
            "color": "@MUTED2@"
          },
          "keyword": {
            "color": "@ANSI5@"
          },
          "label": {
            "color": "@FG@"
          },
          "link_text": {
            "color": "@TEAL@"
          },
          "link_uri": {
            "color": "@TEAL@",
            "font_style": "italic"
          },
          "number": {
            "color": "@ORANGE@"
          },
          "operator": {
            "color": "@OPERATOR@"
          },
          "predictive": {
            "color": "@MUTED2@"
          },
          "preproc": {
            "color": "@TEAL@"
          },
          "primary": {
            "color": "@FG@"
          },
          "property": {
            "color": "@FG@"
          },
          "punctuation": {
            "color": "@OPERATOR@"
          },
          "punctuation.bracket": {
            "color": "@OPERATOR@"
          },
          "punctuation.delimiter": {
            "color": "@OPERATOR@"
          },
          "punctuation.list_marker": {
            "color": "@OPERATOR@"
          },
          "punctuation.special": {
            "color": "@OPERATOR@"
          },
          "string": {
            "color": "@ANSI2@"
          },
          "string.escape": {
            "color": "@ANSI5@"
          },
          "string.regex": {
            "color": "@ANSI2@"
          },
          "tag": {
            "color": "@ANSI1@"
          },
          "type": {
            "color": "@TYPE@"
          },
          "variable": {
            "color": "@FG@"
          },
          "variable.special": {
            "color": "@ANSI1@"
          }
        },
        "tab.active_background": "#00000000",
        "tab.inactive_background": "#00000000",
        "tab_bar.background": "#00000000",
        "terminal.ansi.background": "#00000000",
        "terminal.ansi.black": "@ANSI0@",
        "terminal.ansi.blue": "@ACCENT@",
        "terminal.ansi.bright_black": "@ANSI8@",
        "terminal.ansi.bright_blue": "@ACCENT@",
        "terminal.ansi.bright_cyan": "@ANSI6@",
        "terminal.ansi.bright_green": "@ANSI2@",
        "terminal.ansi.bright_magenta": "@ANSI5@",
        "terminal.ansi.bright_red": "@ANSI1@",
        "terminal.ansi.bright_white": "@FG@",
        "terminal.ansi.bright_yellow": "@ANSI3@",
        "terminal.ansi.cyan": "@ANSI6@",
        "terminal.ansi.dim_black": null,
        "terminal.ansi.dim_blue": null,
        "terminal.ansi.dim_cyan": null,
        "terminal.ansi.dim_green": null,
        "terminal.ansi.dim_magenta": null,
        "terminal.ansi.dim_red": null,
        "terminal.ansi.dim_white": null,
        "terminal.ansi.dim_yellow": null,
        "terminal.ansi.green": "@ANSI2@",
        "terminal.ansi.magenta": "@ANSI5@",
        "terminal.ansi.red": "@ANSI1@",
        "terminal.ansi.white": "@ANSI7@",
        "terminal.ansi.yellow": "@ANSI3@",
        "terminal.background": "#00000000",
        "terminal.bright_foreground": null,
        "terminal.dim_foreground": null,
        "terminal.foreground": "@FG@",
        "text": "@FG@",
        "text.accent": "@ACCENT@",
        "text.disabled": "@ANSI8@",
        "text.muted": "@ANSI7@",
        "text.placeholder": "@MUTED@",
        "title_bar.background": "@ZED_BG@",
        "title_bar.inactive_background": "@ZED_BG@",
        "toolbar.background": "#00000000",
        "unreachable": "@ANSI1@",
        "unreachable.background": "@BG@",
        "unreachable.border": "@ANSI8@",
        "warning": "@ANSI3@",
        "warning.background": "@BG@",
        "warning.border": "@ANSI8@",
        "version_control.added": "@ANSI2@",
        "version_control.added_background": "@BG@",
        "version_control.conflict": "@ANSI5@",
        "version_control.conflict_background": "@BG@",
        "version_control.deleted": "@ANSI1@",
        "version_control.deleted_background": "@BG@",
        "version_control.ignored": "@MUTED@",
        "version_control.modified": "@ANSI3@",
        "version_control.modified_background": "@BG@",
        "version_control.renamed": "@ANSI6@",
        "players": [
          {
            "cursor": "@ACCENT@",
            "background": "@ACCENT@",
            "selection": "@ACCENT@55"
          }
        ]
      }
    }
  ]
}
