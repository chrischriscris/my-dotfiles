import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: root

    // ── Shared state (across all screens) ────────────────────────────────────

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property url screenshotPath: ""
    property real blurPass1Amount: 0.40
    property real blurPass1Max: 64
    property real blurPass1Multiplier: 0.25
    property real blurPass1Saturation: 0.00

    property real blurPass2Amount: 0.40
    property real blurPass2Max: 64
    property real blurPass2Multiplier: 0.25
    property real blurPass2Saturation: 0.10

    property real tintOpacity: 0.60
    property real ditherStrength: 0.01

    onCurrentTextChanged: showFailure = false

    // ── Lock trigger via loginctl (D-Bus Lock signal) ────────────────────────

    Process {
        id: lockMonitor
        running: true
        command: [
            "gdbus", "monitor", "--system",
            "--dest", "org.freedesktop.login1"
        ]

        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf(".Session.Lock ()") !== -1) {
                    // Take a screenshot before locking (screencopy is blocked once locked)
                    screenshotProcess.running = true;
                }
            }
        }

        // Auto-restart if the monitor dies
        onRunningChanged: {
            if (!running) running = true;
        }
    }

    // ── Screenshot capture (runs before lock engages) ────────────────────────

    Process {
        id: screenshotProcess
        command: ["grim", "-l", "0", "/tmp/qs-lockscreen-bg.png"]

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // Bust the image cache by appending a timestamp query
                root.screenshotPath = "file:///tmp/qs-lockscreen-bg.png?" + Date.now();
            } else {
                root.screenshotPath = "";
            }
            lock.locked = true;
        }
    }

    // ── PAM authentication ───────────────────────────────────────────────────

    function tryUnlock() {
        if (currentText === "") return;
        unlockInProgress = true;
        pam.start();
    }

    PamContext {
        id: pam

        configDirectory: "pam"
        config: "password.conf"

        // pam_unix asks for the password — respond immediately with what the user typed
        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText);
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                lock.locked = false;
                root.currentText = "";
                root.showFailure = false;
            } else {
                root.currentText = "";
                root.showFailure = true;
            }

            root.unlockInProgress = false;
        }
    }

    // ── Session lock ─────────────────────────────────────────────────────────

    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            color: "#000000"

            LockSurface {
                anchors.fill: parent
                lockContext: root
            }
        }
    }
}
