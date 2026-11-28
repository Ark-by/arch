import Quickshell
import Quickshell.Io

ShellRoot {
    Background {}
    Bar {}
    Launcher {}
    WallpaperPicker {}
    ThemePicker {}
    PowerMenu {}
    ShortcutsMenu {}

    // Команды, которые вызывает Hyprland по горячим клавишам
    IpcHandler {
        target: "ui"
        function launcher(): void   { UiState.toggle("launcher") }
        function wallpapers(): void { UiState.toggle("wallpaper") }
        function themes(): void     { UiState.toggle("themes") }
        function power(): void      { UiState.toggle("power") }
        function shortcuts(): void  { UiState.toggle("shortcuts") }
    }
}
