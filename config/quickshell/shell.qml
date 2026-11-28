import Quickshell
import Quickshell.Io

ShellRoot {
    Background {}
    Bar {}
    Launcher {}
    PowerMenu {}
    ShortcutsMenu {}
    SettingsWindow { id: settingsWin }
    WallpaperPreview {}

    // Команды, которые вызывает Hyprland по горячим клавишам
    IpcHandler {
        target: "ui"
        function launcher(): void   { UiState.toggle("launcher") }
        // обои и темы живут в окне настроек: Super+W / Super+T открывают нужную страницу
        function wallpapers(): void { settingsWin.togglePage(1) }
        function themes(): void     { settingsWin.togglePage(0) }
        function settings(): void   { UiState.toggle("settings") }
        function power(): void      { UiState.toggle("power") }
        function shortcuts(): void  { UiState.toggle("shortcuts") }
    }
}
