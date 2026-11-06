import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Data from contents/code/fetch.sh (see that script for the shape)
    property var gh: null
    property string errorText: ""
    property bool loading: false
    property date lastUpdated

    readonly property bool hasData: gh !== null && gh.ok === true
    readonly property int reviewCount: hasData ? gh.reviews.total : 0
    readonly property int failingCount: hasData ? gh.mine.items.filter(p => p.ci === "FAILURE" || p.ci === "ERROR").length : 0
    readonly property string notificationsText: !hasData || gh.notifications < 0 ? "?"
        : (gh.notificationsMore ? "50+" : String(gh.notifications))
    readonly property string scriptPath: Qt.resolvedUrl("../code/fetch.sh").toString().replace(/^file:\/\//, "")

    Plasmoid.icon: "vcs-merge-request"
    Plasmoid.status: reviewCount > 0 || failingCount > 0
        ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.ActiveStatus

    // Full view on the desktop, icon + badge in a panel
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation
    switchWidth: Kirigami.Units.gridUnit * 14
    switchHeight: Kirigami.Units.gridUnit * 12

    toolTipMainText: i18n("GitHub")
    toolTipSubText: errorText !== "" ? errorText
        : !hasData ? i18n("Loading…")
        : i18n("%1 to review · %2 open PRs · %3 notifications", reviewCount, gh.mine.total, notificationsText)

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onTriggered: root.refresh()
        },
        PlasmaCore.Action {
            text: i18n("Open GitHub Notifications")
            icon.name: "notifications"
            onTriggered: Qt.openUrlExternally("https://github.com/notifications")
        }
    ]

    function refresh() {
        if (loading) return
        loading = true
        // The trailing comment makes each command unique, so the engine runs it again
        executable.connectSource("bash '" + scriptPath + "' " + Plasmoid.configuration.itemLimit + " #" + Date.now())
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            disconnectSource(source)
            root.loading = false
            const out = (data["stdout"] || "").trim()
            try {
                const parsed = JSON.parse(out)
                if (parsed.ok) {
                    root.gh = parsed
                    root.errorText = ""
                    root.lastUpdated = new Date()
                } else {
                    root.errorText = parsed.error || i18n("Unknown error")
                }
            } catch (e) {
                root.errorText = ((data["stderr"] || out || String(e)) + "").slice(0, 300)
            }
        }
    }

    Timer {
        interval: Math.max(1, Plasmoid.configuration.refreshMinutes) * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // ---------- Panel: icon with a badge (reviews waiting, else failing CI) ----------
    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: compact.containsMouse
        }

        Rectangle {
            readonly property int count: root.reviewCount > 0 ? root.reviewCount : root.failingCount
            visible: count > 0
            anchors.right: parent.right
            anchors.top: parent.top
            width: Math.max(height, badgeLabel.implicitWidth + Kirigami.Units.smallSpacing * 2)
            height: Math.round(parent.height * 0.5)
            radius: height / 2
            color: root.reviewCount > 0 ? Kirigami.Theme.highlightColor : Kirigami.Theme.negativeTextColor

            PlasmaComponents3.Label {
                id: badgeLabel
                anchors.centerIn: parent
                text: parent.count > 99 ? "99+" : parent.count
                color: Kirigami.Theme.highlightedTextColor
                font.pixelSize: parent.height * 0.7
                font.bold: true
            }
        }
    }

    // ---------- Full view ----------
    fullRepresentation: PlasmaExtras.Representation {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 24
        Layout.preferredHeight: Kirigami.Units.gridUnit * 26
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * 12
        collapseMarginsHint: true

        header: PlasmaExtras.PlasmoidHeading {
            RowLayout {
                anchors.fill: parent

                Kirigami.Icon {
                    source: "vcs-merge-request"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                }
                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 3
                    text: root.hasData ? i18n("GitHub · %1", root.gh.login) : i18n("GitHub")
                    elide: Text.ElideRight
                }
                PlasmaComponents3.ToolButton {
                    icon.name: "notifications"
                    text: root.notificationsText
                    display: PlasmaComponents3.AbstractButton.TextBesideIcon
                    onClicked: Qt.openUrlExternally("https://github.com/notifications")
                    PlasmaComponents3.ToolTip.text: i18n("Unread notifications")
                    PlasmaComponents3.ToolTip.visible: hovered
                }
                PlasmaComponents3.BusyIndicator {
                    visible: root.loading
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    running: root.loading
                }
                PlasmaComponents3.ToolButton {
                    visible: !root.loading
                    icon.name: "view-refresh"
                    onClicked: root.refresh()
                    PlasmaComponents3.ToolTip.text: root.hasData
                        ? i18n("Refresh (updated %1)", Qt.formatTime(root.lastUpdated, Locale.ShortFormat))
                        : i18n("Refresh")
                    PlasmaComponents3.ToolTip.visible: hovered
                }
            }
        }

        contentItem: PlasmaComponents3.ScrollView {
            id: scroll
            PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

            // Start at the top once the first data arrives
            property bool scrolledToTop: false
            Connections {
                target: root
                function onGhChanged() {
                    if (!scroll.scrolledToTop) {
                        scroll.scrolledToTop = true
                        Qt.callLater(() => { scroll.contentItem.contentY = 0 })
                    }
                }
            }

            ColumnLayout {
                width: scroll.availableWidth
                spacing: Kirigami.Units.smallSpacing

                PlasmaExtras.PlaceholderMessage {
                    visible: root.errorText !== "" && !root.hasData
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.gridUnit
                    iconName: "dialog-warning"
                    text: i18n("Couldn't load GitHub data")
                    explanation: root.errorText
                }

                PlasmaComponents3.Label {
                    visible: root.errorText !== "" && root.hasData
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    text: i18n("Last refresh failed: %1", root.errorText)
                    color: Kirigami.Theme.negativeTextColor
                    wrapMode: Text.Wrap
                    font: Kirigami.Theme.smallFont
                }

                // --- Review requested ---
                Kirigami.Heading {
                    visible: root.hasData
                    level: 4
                    text: i18n("Review requested (%1)", root.reviewCount)
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                }
                PlasmaComponents3.Label {
                    visible: root.hasData && root.reviewCount === 0
                    text: i18n("Nothing waiting for you 🎉")
                    opacity: 0.7
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                }
                Repeater {
                    model: root.hasData ? root.gh.reviews.items : []
                    delegate: PrRow { pr: modelData; showCi: false }
                }

                // --- My open PRs ---
                Kirigami.Heading {
                    visible: root.hasData
                    level: 4
                    text: root.hasData && root.gh.mine.total > root.gh.mine.items.length
                        ? i18n("My open PRs (%1 of %2)", root.gh.mine.items.length, root.gh.mine.total)
                        : i18n("My open PRs (%1)", root.hasData ? root.gh.mine.total : 0)
                    Layout.topMargin: Kirigami.Units.largeSpacing
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                }
                Repeater {
                    model: root.hasData ? root.gh.mine.items : []
                    delegate: PrRow { pr: modelData; showCi: true }
                }

                PlasmaComponents3.ToolButton {
                    visible: root.hasData
                    focusPolicy: Qt.NoFocus   // taking focus would scroll the list to the bottom
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    text: i18n("All my pull requests on GitHub")
                    icon.name: "internet-web-browser"
                    onClicked: Qt.openUrlExternally("https://github.com/pulls")
                }
            }
        }
    }
}
