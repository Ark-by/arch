pragma Singleton
import QtQuick
import Quickshell

// Основные команды cmus (bind <key> <command>).
Singleton {
    readonly property var commands: [
        "player-play", "player-pause", "player-play-pause", "player-stop",
        "player-next", "player-prev", "player-ff", "player-rew",
        "player-toggle", "seek +1", "seek -1", "seek +5", "seek -5",
        "vol +5%", "vol -5%", "vol +1%", "vol -1%",
        "toggle", "pause", "play", "stop", "next", "prev",
        "view 1", "view 2", "view 3", "view 4", "view 5", "view 6", "view 7",
        "win-up", "win-down", "win-left", "win-right", "win-top", "win-bottom",
        "win-next", "win-prev", "win-page-up", "win-page-down",
        "add", "clear", "save", "load", "save-playlist", "load-playlist",
        "set repeat", "set shuffle", "set softvol", "unset",
        "search", "search-next", "search-prev",
        "sort", "tqueue", "status", "echo", "refresh", "update-cache",
        "cd", "mkdir", "pwd", "run", "shell", "quit", "suspend", "filter", "mark", "unmark"
    ]
}