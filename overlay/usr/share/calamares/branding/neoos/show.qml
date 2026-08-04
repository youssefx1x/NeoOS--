/* NeoOS slideshow for Calamares — terminal-first theme. */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        interval: 20000
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: "NeoOS 13\n\nInstall NeoOS — a Debian 13 (trixie) terminal distribution\n\nCode · Internet · Drivers · Wayland · Wine · Tools"
            color: "#e6edf3"
            font.pointSize: 20
            font.family: "monospace"
        }
    }

    Slide {
        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: "Terminal-first by design\n\nYour start menu (neos-menu), package manager (pkg),\nand the whole NeoLIBs / Wine toolchain are yours.\n\nThank you for choosing NeoOS."
            color: "#e6edf3"
            font.pointSize: 19
            font.family: "monospace"
        }
    }
}
