import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_refreshMinutes: refreshSpin.value
    property alias cfg_itemLimit: limitSpin.value

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: refreshSpin
            Kirigami.FormData.label: i18n("Refresh every (minutes):")
            from: 1
            to: 120
        }
        QQC2.SpinBox {
            id: limitSpin
            Kirigami.FormData.label: i18n("Pull requests per list:")
            from: 1
            to: 50
        }
    }
}
