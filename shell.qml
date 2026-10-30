// BASEUS — Quickshell Entrypoint
// Copyright (c) 2026 xoradesu — MIT License
//
// This is the Quickshell shell manifest. It defines the shell identity
// and loads the root Shell component.
//
// Quickshell reads this file as the project entrypoint.

import Quickshell
import QtQuick
import "src"

ShellRoot {
    // BASEUS shell root — delegates to src/Shell.qml
    Shell {}
}
