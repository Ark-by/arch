pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0
    property real memPct: 0
    property real memUsed: 0       // ГиБ
    property real memTotal: 0
    property real swapPct: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property real netDown: 0       // байт/с
    property real netUp: 0
    property var cpuHistory: []
    property var memHistory: []
    property var extra: ({})

    property real _prevTotal: 0
    property real _prevIdle: 0
    property real _prevRx: -1
    property real _prevTx: 0
    property real _prevTime: 0

    function fmtSpeed(b) {
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " МБ/с"
        if (b >= 1024) return Math.round(b / 1024) + " КБ/с"
        return Math.round(b) + " Б/с"
    }

    function push(arr, v) { return arr.concat([v]).slice(-60) }

    // Процессор: считаем долю занятого времени между двумя замерами
    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = f[3] + (f[4] || 0)
            const total = f.slice(0, 8).reduce((a, b) => a + b, 0)
            if (root._prevTotal > 0) {
                const dt = total - root._prevTotal
                const di = idle - root._prevIdle
                root.cpu = dt > 0 ? 100 * (1 - di / dt) : 0
                root.cpuHistory = root.push(root.cpuHistory, root.cpu)
            }
            root._prevTotal = total
            root._prevIdle = idle
        }
    }

    // Память и подкачка
    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: {
            const t = text()
            const get = k => {
                const m = t.match(new RegExp("^" + k + ":\\s+(\\d+)", "m"))
                return m ? Number(m[1]) : 0
            }
            const total = get("MemTotal"), avail = get("MemAvailable")
            const sTotal = get("SwapTotal"), sFree = get("SwapFree")
            root.memTotal = total / 1048576
            root.memUsed = (total - avail) / 1048576
            root.memPct = total > 0 ? 100 * (total - avail) / total : 0
            root.swapTotal = sTotal / 1048576
            root.swapUsed = (sTotal - sFree) / 1048576
            root.swapPct = sTotal > 0 ? 100 * (sTotal - sFree) / sTotal : 0
            root.memHistory = root.push(root.memHistory, root.memPct)
        }
    }

    // Сеть: считаем только реальные адаптеры (en*, eth*, wl*), без VPN и WARP,
    // иначе один и тот же трафик посчитался бы дважды
    FileView {
        id: netFile
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0
            for (const l of text().split("\n").slice(2)) {
                const p = l.trim().split(/[:\s]+/)
                if (p.length < 10 || !/^(en|eth|wl)/.test(p[0])) continue
                rx += Number(p[1])
                tx += Number(p[9])
            }
            const now = Date.now()
            if (root._prevRx >= 0 && now > root._prevTime) {
                const s = (now - root._prevTime) / 1000
                root.netDown = Math.max(0, (rx - root._prevRx) / s)
                root.netUp = Math.max(0, (tx - root._prevTx) / s)
            }
            root._prevRx = rx
            root._prevTx = tx
            root._prevTime = now
        }
    }

    // Раз в секунду перечитываем быстрые данные
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { statFile.reload(); memFile.reload(); netFile.reload() }
    }

    // Диск, температура и видеокарта: только пока открыто окно монитора
    Timer {
        interval: 5000
        repeat: true
        triggeredOnStart: true
        running: UiState.panel === "monitor"
        onTriggered: extraProc.running = true
    }

    Process {
        id: extraProc
        command: [Quickshell.env("HOME") + "/.local/bin/sysinfo-extra"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.extra = JSON.parse(text) } catch (e) {}
            }
        }
    }
}
