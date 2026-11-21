import Quickshell
import Quickshell.Io

ShellRoot {
    Background {}
    Bar {}
    Launcher {}
    WallpaperPicker {}
    ThemePicker {}
    PowerMenu {}
    MonitorMenu {}
    ShortcutsMenu {}
    ServicesMenu {}

    // Команды, которые вызывает Hyprland по горячим клавишам
    IpcHandler {
        target: "ui"
        function launcher(): void   { UiState.toggle("launcher") }
        function wallpapers(): void { UiState.toggle("wallpaper") }
        function themes(): void     { UiState.toggle("themes") }
        function power(): void      { UiState.toggle("power") }
        function monitor(): void    { UiState.toggle("monitor") }
        function shortcuts(): void  { UiState.toggle("shortcuts") }
        function services(): void   { UiState.toggle("services") }
    }
}
