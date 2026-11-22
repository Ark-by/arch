# ark.zsh-theme
# ark
#
# Rebuild of the oh-my-zsh gnzh theme (itself based on bira).
# Two lines, box-drawing frame, virtualenv and ruby version, git branch, exit code on the right.
#
# Built with Simple Zsh Theme. Drop this file in
#   ~/.oh-my-zsh/custom/themes/
# and set ZSH_THEME="ark" in ~/.zshrc.

# Required so $(...) and ${...} inside PROMPT are evaluated per prompt.
setopt prompt_subst

# --------------------------------------------------------------------
# Segment settings
# --------------------------------------------------------------------

# Stops a virtualenv's activate script prepending "(name) " to PS1, where it
# would sit ahead of this whole prompt instead of in its own segment.
export VIRTUAL_ENV_DISABLE_PROMPT='1'

# --------------------------------------------------------------------
# Helper functions
# --------------------------------------------------------------------

# Active Python virtualenv, without needing the oh-my-zsh plugin
zsh_theme_virtualenv() {
  [[ -n "$VIRTUAL_ENV" ]] || return
  # VIRTUAL_ENV_PROMPT is what `python -m venv --prompt` stores; fall back to
  # the directory name. Percent signs are doubled so a venv called "100%" does
  # not turn into a prompt escape.
  local name=${VIRTUAL_ENV_PROMPT:-${VIRTUAL_ENV:t}}
  echo "${ZSH_THEME_VIRTUALENV_PREFIX}${name:gs/%/%%}${ZSH_THEME_VIRTUALENV_SUFFIX}"
}

# Mark remote sessions so %(1V...) can test for SSH
# Why psvar rather than ${SSH_TTY:+...} inside PROMPT: zsh ends a ${...}
# expansion at the FIRST unescaped '}', so the '}' of a nested %F{color} closes
# it early and the leftover brace is printed literally. A prompt conditional has
# no such problem, and needs no prompt_subst.
zsh_theme_ssh_psvar_precmd() {
  psvar[1]=${SSH_TTY:+1}
}


# --------------------------------------------------------------------
# Hooks
# --------------------------------------------------------------------

autoload -Uz add-zsh-hook
add-zsh-hook precmd zsh_theme_ssh_psvar_precmd

# --------------------------------------------------------------------
# Git appearance (read by oh-my-zsh's git_prompt_* functions)
# --------------------------------------------------------------------

ZSH_THEME_GIT_PROMPT_PREFIX='%F{yellow}‹'
ZSH_THEME_GIT_PROMPT_SUFFIX='› %f'
ZSH_THEME_GIT_PROMPT_DIRTY=''
ZSH_THEME_GIT_PROMPT_CLEAN=''

# --------------------------------------------------------------------
# Dev-environment appearance
# --------------------------------------------------------------------

ZSH_THEME_VIRTUALENV_PREFIX='%F{red}('
ZSH_THEME_VIRTUALENV_SUFFIX=')%f '
ZSH_THEME_RUBY_PROMPT_PREFIX='%F{red}‹'
ZSH_THEME_RUBY_PROMPT_SUFFIX='›%f'

# --------------------------------------------------------------------
# The prompt
# --------------------------------------------------------------------

PROMPT='╭─$(zsh_theme_virtualenv)%F{green}%(1V.%F{red}.)%(!.%F{red}.)%n%f%F{cyan}@%f%F{green}%(1V.%F{red}.)%(!.%F{red}.)%(1V.%M.%m)%f %F{blue}%B%~%b%f $(ruby_prompt_info) $(git_prompt_info)
╰─%(!.%F{red}.)➤%(!.%f.) '

RPROMPT='%(?..%F{red}%? ↵%f)'

