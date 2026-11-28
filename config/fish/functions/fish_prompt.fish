function fish_prompt --description 'Промпт: каталог, git-ветка, код возврата'
    set -l last_status $status

    # каталог: ~ вместо /home/ark, длинные пути сокращаются
    set_color brblue
    printf '%s' (prompt_pwd)

    # git-ветка, если внутри репозитория
    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null)
    if test -n "$branch"
        set_color brblack
        printf ' (%s)' "$branch"
    end

    # код возврата предыдущей команды, если он не нулевой
    if test $last_status -ne 0
        set_color brred
        printf ' [%s]' $last_status
    end

    set_color normal
    printf '\n'

    # стрелка: зелёная при успехе, красная при ошибке
    if test $last_status -eq 0
        set_color green
    else
        set_color red
    end
    printf '❯ '
    set_color normal
end
