import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// One pull request: CI/status glyph, title, and "owner/repo #123 · by author"
PlasmaComponents3.ItemDelegate {
    id: row

    property var pr
    property bool showCi: false

    readonly property var ciGlyph: ({
        "SUCCESS": { text: "✓", color: Kirigami.Theme.positiveTextColor, tip: i18n("Checks passed") },
        "FAILURE": { text: "✗", color: Kirigami.Theme.negativeTextColor, tip: i18n("Checks failed") },
        "ERROR":   { text: "✗", color: Kirigami.Theme.negativeTextColor, tip: i18n("Checks errored") },
        "PENDING": { text: "●", color: Kirigami.Theme.neutralTextColor, tip: i18n("Checks running") },
        "EXPECTED":{ text: "●", color: Kirigami.Theme.neutralTextColor, tip: i18n("Checks expected") },
        "NONE":    { text: "–", color: Kirigami.Theme.disabledTextColor, tip: i18n("No checks") }
    })
    readonly property var ci: ciGlyph[pr && pr.ci ? pr.ci : "NONE"] || ciGlyph["NONE"]

    Layout.fillWidth: true
    focusPolicy: Qt.NoFocus   // keep the list from auto-scrolling to a focused row
    onClicked: Qt.openUrlExternally(pr.url)

    PlasmaComponents3.ToolTip.text: pr ? pr.title + (showCi ? "\n" + ci.tip : "") : ""
    PlasmaComponents3.ToolTip.visible: hovered
    PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing * 2

        PlasmaComponents3.Label {
            visible: row.showCi
            text: row.ci.text
            color: row.ci.color
            font.bold: true
            Layout.preferredWidth: Kirigami.Units.gridUnit
            horizontalAlignment: Text.AlignHCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: (row.pr.draft ? i18n("[Draft] ") : "") + row.pr.title
                elide: Text.ElideRight
                opacity: row.pr.draft ? 0.7 : 1
            }
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: row.pr.repo + " #" + row.pr.number + (row.pr.author ? i18n(" · by %1", row.pr.author) : "")
                elide: Text.ElideMiddle
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }
        }
    }
}
