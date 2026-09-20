// Component tests, run with qmltestrunner (Qt's own QML test harness):
//
//   qmltestrunner -input tests
//
// These synthesise key and mouse events inside Qt, which is the only way to
// exercise a greeter theme's focus and keyboard behaviour without a display
// manager and a real seat.
import QtQuick
import QtTest
import ".." as Theme
import "../components" as Components

Item {
    id: root
    width: 600
    height: 400

    ListModel {
        id: sessions
        ListElement { name: "Hyprland" }
        ListElement { name: "Hyprland (uwsm-managed)" }
        ListElement { name: "Plasma" }
    }

    Components.MatrixField {
        id: field
        x: 20
        y: 20
        width: 560
        label: "PASS"
        echoMode: TextInput.Password
    }

    Components.MatrixSelect {
        id: select
        x: 20
        y: 80
        width: 560
        label: "SESSION"
        model: sessions
    }

    Components.MatrixButton {
        id: button
        x: 20
        y: 160
        label: "LOGIN"
    }

    TestCase {
        name: "MatrixField"
        when: windowShown

        function init() {
            field.text = "";
            field.forceActiveFocus();
        }

        function test_password_is_masked() {
            keyClick(Qt.Key_S);
            keyClick(Qt.Key_E);
            keyClick(Qt.Key_C);
            compare(field.text, "sec");
            verify(field.echoMode === TextInput.Password);
        }

        function test_enter_emits_accepted() {
            var accepted = 0;
            function count() { accepted += 1; }
            field.accepted.connect(count);
            keyClick(Qt.Key_Return);
            field.accepted.disconnect(count);
            compare(accepted, 1);
        }

        function test_focus_is_visible_to_a_parent() {
            verify(field.inputFocused);
        }
    }

    TestCase {
        name: "MatrixSelect"
        when: windowShown

        function init() {
            select.expanded = false;
            select.setIndex(0);
            select.forceActiveFocus();
        }

        function test_model_text_is_readable_outside_a_view() {
            compare(select.count, 3);
            compare(select.itemText(0), "Hyprland");
            compare(select.itemText(2), "Plasma");
            compare(select.currentText, "Hyprland");
        }

        function test_space_toggles_the_dropdown() {
            verify(!select.expanded);
            keyClick(Qt.Key_Space);
            verify(select.expanded);
            keyClick(Qt.Key_Space);
            verify(!select.expanded);
        }

        function test_escape_closes_the_dropdown() {
            keyClick(Qt.Key_Space);
            verify(select.expanded);
            keyClick(Qt.Key_Escape);
            verify(!select.expanded);
        }

        function test_arrows_move_the_selection_without_closing() {
            keyClick(Qt.Key_Space);
            keyClick(Qt.Key_Down);
            compare(select.currentIndex, 1);
            compare(select.currentText, "Hyprland (uwsm-managed)");
            verify(select.expanded);
            keyClick(Qt.Key_Up);
            compare(select.currentIndex, 0);
        }

        function test_selection_stops_at_the_ends() {
            keyClick(Qt.Key_Up);
            compare(select.currentIndex, 0);
            select.setIndex(2);
            keyClick(Qt.Key_Down);
            compare(select.currentIndex, 2);
        }

        function test_click_opens_the_dropdown() {
            mouseClick(select, select.width / 2, select.height / 2);
            verify(select.expanded);
        }

        function test_indexOfName() {
            compare(select.indexOfName("Plasma"), 2);
            compare(select.indexOfName("nope"), -1);
        }
    }

    Theme.MatrixRain {
        id: rain
        x: 0
        y: 220
        width: 560
        height: 160
        fontSize: 12
    }

    TestCase {
        name: "MatrixRain"
        when: windowShown

        function test_streams_are_created_once_and_cover_the_width() {
            verify(rain.columnCount > 1);
            compare(rain.streams.length, rain.columnCount);
            verify(rain.columnCount <= rain.maxColumns);
        }

        function test_glyph_alphabet_is_not_empty() {
            verify(rain.glyphs.length > 50);
            verify(rain.randomGlyph().length === 1);
        }
    }

    TestCase {
        name: "TabChain"
        when: windowShown

        // The order a user actually tabs through: password, then the session
        // dropdown, then the button. A read-only input in the chain used to
        // swallow this.
        function test_tab_moves_password_to_select_to_button() {
            field.forceActiveFocus();
            verify(field.inputFocused);
            keyClick(Qt.Key_Tab);
            verify(select.focused);
            keyClick(Qt.Key_Tab);
            verify(button.activeFocus);
        }
    }

    TestCase {
        name: "MatrixButton"
        when: windowShown

        function test_click_and_enter_both_activate() {
            var clicks = 0;
            function count() { clicks += 1; }
            button.clicked.connect(count);
            mouseClick(button, button.width / 2, button.height / 2);
            button.forceActiveFocus();
            keyClick(Qt.Key_Return);
            button.clicked.disconnect(count);
            compare(clicks, 2);
        }
    }
}
