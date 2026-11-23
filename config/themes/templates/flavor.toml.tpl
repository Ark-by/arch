# vim:fileencoding=utf-8:foldmethod=marker

# : Manager {{{

[mgr]
cwd = { fg = "@ACCENT@" }

# Find
find_keyword  = { fg = "@ANSI1@", bold = true, italic = true, underline = true }
find_position = { fg = "@ANSI5@", bg = "reset", bold = true, italic = true }

# Marker
marker_copied   = { fg = "@ANSI2@", bg = "@ANSI2@" }
marker_cut      = { fg = "@ANSI3@", bg = "@ANSI1@" }
marker_marked   = { fg = "@ACCENT@", bg = "@ANSI6@" }
marker_selected = { fg = "@ANSI3@", bg = "@ANSI3@" }

# Count
count_copied   = { fg = "@BG@", bg = "@ANSI2@" }
count_cut      = { fg = "@BG@", bg = "@ANSI3@" }
count_selected = { fg = "@BG@", bg = "@ACCENT@" }

# Border
border_symbol = "│"
border_style  = { fg = "@ANSI8@" }

# : }}}


# : Tabs {{{

[tabs]
active   = { fg = "@SURFACE@", bg = "@ACCENT@", bold = true }
inactive = { fg = "@ACCENT@", bg = "@SURFACE@" }

# : }}}


# : Mode {{{

[mode]

normal_main = { fg = "@SURFACE@", bg = "@ACCENT@", bold = true }
normal_alt  = { fg = "@ACCENT@", bg = "@SURFACE@" }

# Select mode
select_main = { fg = "@SURFACE@", bg = "@ANSI2@", bold = true }
select_alt  = { fg = "@ACCENT@", bg = "@SURFACE@" }

# Unset mode
unset_main = { fg = "@SURFACE@", bg = "@ANSI5@", bold = true }
unset_alt  = { fg = "@ACCENT@", bg = "@SURFACE@" }

# : }}}


# : Status bar {{{

[status]
overall = { fg = "@ACCENT@" }
sep_left  = { open = "", close = "" }
sep_right = { open = "", close = "" }


# Progress
progress_label = { fg = "@SURFACE@", bold = true }
progress_normal = { fg = "@ACCENT@", bg = "@SURFACE@" }
progress_error = { fg = "@ANSI1@", bg = "@SURFACE@" }

# Permissions
perm_sep   = { fg = "@ACCENT@" }
perm_type  = { fg = "@ANSI2@" }
perm_read  = { fg = "@ANSI3@" }
perm_write = { fg = "@ANSI1@" }
perm_exec  = { fg = "@ANSI5@" }


# : }}}

# : Pick {{{

[pick]
border = { fg = "@ACCENT@" }
active = { fg = "@ANSI5@", bold = true }
inactive = {}

# : }}}


# : Input {{{

[input]
border   = { fg = "@ACCENT@" }
title    = {}
value    = {}
selected = { reversed = true }

# : }}}


# : Completion {{{

[cmp]
border = { fg = "@ACCENT@" }

# : }}}


# : Tasks {{{

[tasks]
border  = { fg = "@ACCENT@" }
title   = {}
hovered = { fg = "@ANSI5@", underline = true }

# : }}}


# : Which {{{

[which]
mask            = { bg = "@ANSI8@" }
cand            = { fg = "@ANSI2@" }
rest            = { fg = "@ANSI7@" }
desc            = { fg = "@ANSI5@" }
separator       = "  "
separator_style = { fg = "@MUTED@" }

# : }}}


# : Help {{{

[help]
on      = { fg = "@ANSI2@" }
run     = { fg = "@ANSI5@" }
hovered = { reversed = true, bold = true }
footer  = { fg = "@BG@", bg = "@ANSI7@" }

# : }}}


# : Spotter {{{

[spot]
border   = { fg = "@ACCENT@" }
title    = { fg = "@ACCENT@" }
tbl_col  = { fg = "@ANSI2@" }
tbl_cell = { fg = "@ANSI5@", bg = "@SURFACE@" }

# : }}}


# : Notify {{{

[notify]
title_info  = { fg = "@ANSI2@" }
title_warn  = { fg = "@ANSI1@" }
title_error = { fg = "@ANSI3@" }

# : }}}


# : File-specific styles {{{

[filetype]

rules = [
	# Images
	{ mime = "image/*", fg = "@ANSI3@" },

	# Media
	{ mime = "video/*", fg = "@ANSI1@" },
	{ mime = "audio/*", fg = "@ANSI1@" },

	# Archives
	{ mime = "application/zip",             fg = "@ANSI5@" },
	{ mime = "application/x-tar",           fg = "@ANSI5@" },
	{ mime = "application/x-bzip*",         fg = "@ANSI5@" },
	{ mime = "application/x-bzip2",         fg = "@ANSI5@" },
	{ mime = "application/x-7z-compressed", fg = "@ANSI5@" },
	{ mime = "application/x-rar",           fg = "@ANSI5@" },
	{ mime = "application/x-xz",            fg = "@ANSI5@" },

	# Documents
	{ mime = "application/doc",        fg = "@ANSI2@" },
	{ mime = "application/epub+zip",   fg = "@ANSI2@" },
	{ mime = "application/pdf",        fg = "@ANSI2@" },
	{ mime = "application/rtf",        fg = "@ANSI2@" },
	{ mime = "application/vnd.*",      fg = "@ANSI2@" },

  # Special files
  { mime = "*", is = "orphan", fg = "#f29cb4", bg = "#93000a" },
  { mime = "application/*exec*", fg = "@ANSI1@" },

	# Fallback
	{ url = "*", fg = "@FG@" },
	{ url = "*/", fg = "@ACCENT@" },
]

# : }}}
