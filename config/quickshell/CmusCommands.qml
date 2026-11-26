pragma Singleton
import QtQuick
import Quickshell

// Команды cmus для bind <key> <command> (по man cmus и cheat sheet).
Singleton {
    readonly property var commands: [
        "player-play", "player-pause", "player-play-pause", "player-stop",
        "player-next", "player-prev", "player-ff", "player-rew",
        "player-toggle", "seek +1m", "seek -1m", "seek +5s", "seek -5s",
        "vol +10%", "vol -10%", "vol +5%", "vol -5%", "vol +1%", "vol -1%",
        "toggle", "pause", "play", "stop", "next", "prev",
        "view 0", "view 1", "view 2", "view 3", "view 4", "view 5", "view 6", "view 7",
        "win-up", "win-down", "win-left", "win-right", "win-top", "win-bottom",
        "win-next", "win-prev", "win-page-up", "win-page-down",
        "add", "open", "clear", "save", "load", "save-playlist", "load-playlist",
        "shuffle", "set repeat=true", "set repeat=false",
        "set shuffle=true", "set shuffle=false",
        "set softvol=true", "set softvol=false",
        "set replaygain=0", "set replaygain=1", "set replaygain=2",
        "set auto_reshuffle=true", "set auto_reshuffle=false",
        "set continue=true", "set continue=false",
        "search", "search-next", "search-prev", "live-filter", "filter clear",
        "sort", "tqueue", "status", "echo", "refresh", "update-cache",
        "cd", "mkdir", "pwd", "run", "shell", "quit", "suspend", "filter", "mark", "unmark"
    ]
}