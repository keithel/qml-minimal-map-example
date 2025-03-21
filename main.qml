// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning

Window {
    width: Qt.platform.os == "android" ? Screen.width : 512
    height: Qt.platform.os == "android" ? Screen.height : 512
    visible: true
    title: mapBase.center + " zoom " + mapBase.zoomLevel.toFixed(3)
           + " min " + mapBase.minimumZoomLevel + " max " + mapBase.maximumZoomLevel

    Plugin {
        id: mapPlugin
        name: "osm"
    }

    Map {
        id: mapBase
        anchors.fill: parent
        plugin: mapPlugin
        center: QtPositioning.coordinate(43,-71.45) // Manchester, NH
        zoomLevel: 14
        property geoCoordinate startCentroid

        PinchHandler {
            id: pinch
            target: null
            onActiveChanged: if (active) {
                mapBase.startCentroid = mapBase.toCoordinate(pinch.centroid.position, false)
            }
            onScaleChanged: (delta) => {
                mapBase.zoomLevel += Math.log2(delta)
                mapBase.alignCoordinateToPoint(mapBase.startCentroid, pinch.centroid.position)
            }
            onRotationChanged: (delta) => {
                mapBase.bearing -= delta
                mapBase.alignCoordinateToPoint(mapBase.startCentroid, pinch.centroid.position)
            }
            grabPermissions: PointerHandler.TakeOverForbidden
        }
        WheelHandler {
            id: wheel
            // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
            // Magic Mouse pretends to be a trackpad but doesn't work with PinchHandler
            // and we don't yet distinguish mice and trackpads on Wayland either
            acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                             ? PointerDevice.Mouse | PointerDevice.TouchPad
                             : PointerDevice.Mouse
            rotationScale: 1/120
            property: "zoomLevel"
        }
        DragHandler {
            id: drag
            target: null
            onTranslationChanged: (delta) => mapBase.pan(-delta.x, -delta.y)
        }
        Shortcut {
            enabled: mapBase.zoomLevel < mapBase.maximumZoomLevel
            sequence: StandardKey.ZoomIn
            onActivated: mapBase.zoomLevel = Math.round(mapBase.zoomLevel + 1)
        }
        Shortcut {
            enabled: mapBase.zoomLevel > mapBase.minimumZoomLevel
            sequence: StandardKey.ZoomOut
            onActivated: mapBase.zoomLevel = Math.round(mapBase.zoomLevel - 1)
        }
    }

    Map {
        id: mapOverlay
        anchors.fill: mapBase
        plugin: Plugin { name: "itemsoverlay" }
        center: mapBase.center
        color: 'transparent' // Necessary to make this map transparent
        minimumFieldOfView: mapBase.minimumFieldOfView
        maximumFieldOfView: mapBase.maximumFieldOfView
        minimumTilt: mapBase.minimumTilt
        maximumTilt: mapBase.maximumTilt
        minimumZoomLevel: mapBase.minimumZoomLevel
        maximumZoomLevel: mapBase.maximumZoomLevel
        zoomLevel: mapBase.zoomLevel
        tilt: mapBase.tilt;
        bearing: mapBase.bearing
        fieldOfView: mapBase.fieldOfView
        z: mapBase.z + 1

        MapQuickItem {
            id: imageMQI
            sourceItem: Image {
                source: "qrc:/mapoverlay.png"
            }
            coordinate: QtPositioning.coordinate(42.99486, -71.463457)
            anchorPoint: Qt.point(0,0);
            zoomLevel: zoomLevelControl.checked ? 17 : 0;
            opacity: hoverHandler.hovered

            HoverHandler {
                id: hoverHandler
            }
        }
    }

    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 15
        Button {
            id: zoomLevelControl
            text: "Toggle MapQuickItem zoomLevel"
            checkable: true
            checked: true
        }

        Label {
            color: Qt.black
            text: imageMQI.zoomLevel
        }
    }
}
