pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Настройки меню: default_settings.json (эталон из репозитория) +
// user_settings.json (только переопределения, sparse).
// Чтение — слияние, запись — только изменённые ключи.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
    readonly property string defaultsPath: configDir + "/quickshell/default_settings.json"
    readonly property string userPath: configDir + "/quickshell/user_settings.json"

    property var defaults: ({})
    property var overrides: ({})
    property bool dirty: false
    property bool ready: false

    signal saved()
    signal saveFailed(int code)

    function _isObj(v) {
        return v !== null && typeof v === "object" && !Array.isArray(v)
    }

    function _parse(text, fallback) {
        try {
            const v = JSON.parse(text)
            return _isObj(v) ? v : fallback
        } catch (e) {
            console.log("settings: JSON parse error: " + e)
            return fallback
        }
    }

    function _clone(o) {
        return JSON.parse(JSON.stringify(o))
    }

    // Глубокое слияние: значения из overrides перекрывают эталон
    function merge(base, over) {
        if (!_isObj(base) || !_isObj(over))
            return over === undefined ? base : over
        const out = {}
        for (const k in base)
            out[k] = base[k]
        for (const k in over)
            out[k] = _isObj(base[k]) ? merge(base[k], over[k]) : over[k]
        return out
    }

    // Эффективное значение по пути "bar.height"
    function get(path, fallback) {
        const parts = path.split(".")
        let cur = root.merge(root.defaults, root.overrides)
        for (let i = 0; i < parts.length; i++) {
            if (!_isObj(cur) || !(parts[i] in cur))
                return fallback
            cur = cur[parts[i]]
        }
        return cur === undefined ? fallback : cur
    }

    function isOverridden(path) {
        const parts = path.split(".")
        let cur = root.overrides
        for (let i = 0; i < parts.length; i++) {
            if (!_isObj(cur) || !(parts[i] in cur))
                return false
            cur = cur[parts[i]]
        }
        return true
    }

    // Изменение в памяти — на диск попадёт при apply()
    function set(path, value) {
        const parts = path.split(".")
        const o = root._clone(root.overrides)
        let cur = o
        for (let i = 0; i < parts.length - 1; i++) {
            if (!_isObj(cur[parts[i]]))
                cur[parts[i]] = {}
            cur = cur[parts[i]]
        }
        cur[parts[parts.length - 1]] = value
        root.overrides = o
        root.dirty = true
    }

    // Сброс раздела: убрать переопределения, значения придут из эталона
    function resetSection(name) {
        const o = root._clone(root.overrides)
        delete o[name]
        root.overrides = o
        root.dirty = true
    }

    // Полный сброс: удалить файл переопределений
    function resetAll() {
        root.overrides = ({})
        root.dirty = false
        Quickshell.execDetached(["sh", "-c", "rm -f \"$1\"", "ark", root.userPath])
    }

    function apply() {
        writer.json = JSON.stringify(root.overrides, null, 2) + "\n"
        writer.running = true
    }

    Process {
        id: writer
        property string json: ""
        command: ["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "ark", writer.json, root.userPath]
        onExited: (code, status) => {
            if (code === 0) {
                root.dirty = false
                root.saved()
            } else {
                root.saveFailed(code)
            }
        }
    }

    Process {
        id: readDefaults
        command: ["cat", root.defaultsPath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.defaults = root._parse(this.text, ({}))
                root.ready = true
            }
        }
    }

    Process {
        id: readUser
        command: ["cat", root.userPath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.overrides = root._parse(this.text, ({}))
        }
    }
}