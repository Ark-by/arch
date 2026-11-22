# ─── oh-my-zsh ───────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="ark"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# ─── плагины из pacman (не из oh-my-zsh: они лежат в /usr/share/zsh/plugins) ──
# zsh-autosuggestions должен идти до syntax-highlighting
for _zplugin in \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
    [[ -f "$_zplugin" ]] && source "$_zplugin"
done
unset _zplugin

# ─── приветствие в терминале ─────────────────────────────────────────────────
if [[ -o interactive ]] && command -v fastfetch &>/dev/null; then
    fastfetch
fi
