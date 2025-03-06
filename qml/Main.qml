// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning
import minimal_map

ApplicationWindow {
    id: main
    width: Qt.platform.os === "android" ? Screen.width : 512
    height: Qt.platform.os === "android" ? Screen.height : 512
    visible: true
    title: mapBase.center + " zoom " + mapBase.zoomLevel.toFixed(3)
          + " min " + mapBase.minimumZoomLevel + " max " + mapBase.maximumZoomLevel

    Plugin {
        id: mapPlugin
        name: "osm"
        PluginParameter {
            name: "osm.mapping.providersrepository.address"
            value: AppConfig.osmMappingProvidersRepositoryAddress
        }
    }

    Map {
        id: mapBase
        z: 5
        anchors.fill: parent
        plugin: mapPlugin
        center: QtPositioning.coordinate(43,-71.45) // Manchester, NH
        zoomLevel: 14
        activeMapType: supportedMapTypes[mapChoice.currentIndex]
        property geoCoordinate startCentroid
        property geoCoordinate cursorCoordinate;

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: (mouse) => {
                mapBase.cursorCoordinate = mapBase.toCoordinate(Qt.point(mouseX, mouseY), false);
            }
        }

        Component.onCompleted: {
            mapChoice.model = mapBase.supportedMapTypes.map((mapType) => mapType.name);
            mapChoice.currentIndex = 0;
        }

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
            onActivated: mapBase.zoomLevel = mapBase.zoomLevel + 0.05 //Math.round(mapBase.zoomLevel + 1)
        }
        Shortcut {
            enabled: mapBase.zoomLevel > mapBase.minimumZoomLevel
            sequence: StandardKey.ZoomOut
            onActivated: mapBase.zoomLevel = mapBase.zoomLevel - 0.05 //Math.round(mapBase.zoomLevel - 1)
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

        SequentialAnimation {
            id: seqAnim
            loops: Animation.Infinite
            running: true
            property QtObject target: tiffImgMQI
            property string property: "opacity"
            property real lowVal: 0
            property real highVal: 1
            property int duration: 750

            NumberAnimation {
                target: seqAnim.target
                property: seqAnim.property
                duration: seqAnim.duration
                from: seqAnim.highVal
                to: seqAnim.lowVal
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: seqAnim.target
                property: seqAnim.property
                duration: seqAnim.duration
                from: seqAnim.lowVal
                to: seqAnim.highVal
                easing.type: Easing.InOutQuad
            }
        }

        MapQuickItem {
            id: tiffImgMQI
            sourceItem: Image {
                id: tiffImg
                source: "qrc:/manchester-elm-valley-mammoth-map.tif"
            }
            coordinate: QtPositioning.coordinate(42.99486, -71.463457)
            anchorPoint: Qt.point(0,0);
            zoomLevel: 17;
        }

        // // The code below enables SSAA
        // layer.enabled: true
        // layer.smooth: true
        // property int w : mapOverlay.width
        // property int h : mapOverlay.height
        // property int pr: Screen.devicePixelRatio
        // layer.textureSize: Qt.size(w  * 2 * pr, h * 2 * pr)
    }
    RowLayout {
        z: 10
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10

        ComboBox {
            id: mapChoice
        }

        FontMetrics { id: fm; font: mouseCoords.font }
        TextField {
            id: mouseCoordsDec
            Layout.preferredWidth: fm.boundingRect("-00.00000, -00.00000").width + leftPadding + rightPadding;
            property string tlCoordinateDecimal: mapBase.cursorCoordinate.latitude.toFixed(5) + ", " + mapBase.cursorCoordinate.longitude.toFixed(5);
            readOnly: true
            color: Qt.black
            text: tlCoordinateDecimal
            background: Item { implicitWidth: 200; implicitHeight: 40 }
        }

        TextField {
            id: mouseCoords
            Layout.preferredWidth: fm.boundingRect("00° 00' 00.0\" N, 00° 00' 00.0\" W, 0m").width + leftPadding + rightPadding;
            readOnly: true
            color: Qt.black
            text: mapBase.cursorCoordinate.toString();
            background: Item { implicitWidth: 200; implicitHeight: 40; }
        }
    }
}
