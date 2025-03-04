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

    property var currentMap: null

    Plugin {
        id: mapPlugin
        name: "osm"
        PluginParameter {
            name: "osm.mapping.providersrepository.address"
            value: AppConfig.osmMappingProvidersRepositoryAddress
        }
    }

    // Define GeoShape's ShapeType enum type in qml
    enum ShapeType {
        UnknownType = 0,
        RectangleType,
        CircleType,
        PathType,
        PolygonType
    }

    Map {
        id: mapBase
        z: 5
        anchors.fill: parent
        plugin: mapPlugin
        center: QtPositioning.coordinate(43,-71.45) // Manchester, NH
        zoomLevel: 14
        property geoCoordinate startCentroid
        activeMapType: supportedMapTypes[mapChoice.currentIndex]
        property geoCoordinate topLeftCoordinate;

        Component.onCompleted: {
            var mapTypeNames = mapBase.supportedMapTypes.map((mapType) => mapType.name);
            mapChoice.model = mapBase.supportedMapTypes.map((mapType) => mapType.name);
            mapChoice.currentIndex = 5;
        }

        onVisibleRegionChanged: {
            topLeftCoordinate = toCoordinate(Qt.point(0,0), false);
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
        anchors.fill: parent
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

        function printCenter() {
            console.log(visibleArea.width + ", " + visibleArea.height);
            console.log(width + ", " + height);
            var pixel = Qt.point(width/2, height/2);//Qt.point(0, 0);
            var pixelCoord = toCoordinate(pixel, true);
            console.log("center " + center.latitude + ", " + center.longitude + ", calcCenter == " + pixelCoord.latitude + ", " + pixelCoord.longitude);
        }

        Component.onCompleted: printCenter();
        onCenterChanged: {
            if(height > 0 && width > 0)
                printCenter();
            // Just assume visibleRegion is a GeoShape.RectangleType, as the
            // `GeoShape` namespace seems not to be defined in Qt 6.9.
            // console.log("Center changed, visibleRegion.type: " + visibleRegion.type)
            // if (visibleRegion.type === Main6.ShapeType.RectangleType) {
            //     console.log("visibleRegion is a georectangle")
            //     var vRegionRect = MapUtils.geoShapeToRectangle(visibleRegion); // geoRectangle(visibleRegion);
            //     console.log("vRegionRect bottomLeft: " + vRegionRect.bottomLeft);
            // }
        }

        SequentialAnimation {
            id: seqAnim
            loops: Animation.Infinite
            running: true
            property QtObject target: circle
            property string property: "radius"
            property int lowVal: 10000
            property int highVal: 200000
            property int duration: 2000

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
            coordinate: QtPositioning.coordinate(42.99486, -71.46345)
            anchorPoint: Qt.point(0,0); // Qt.point(tiffImg.width/2, tiffImg.height/2)
            zoomLevel: 17;
        }

        MapCircle {
            id: circle
            center: QtPositioning.coordinate(43,-71.45)
            radius: 200000
            border.width: 5

            // MouseArea {
            //     anchors.fill: parent
            //     drag.target: parent
            // }
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

        TextField {
            id: mouseCoordsDec
            Layout.preferredWidth: fm.boundingRect("-00.00000, -00.00000").width + leftPadding + rightPadding;
            property string tlCoordinateDecimal: mapBase.topLeftCoordinate.latitude.toFixed(5) + ", " + mapBase.topLeftCoordinate.longitude.toFixed(5);
            readOnly: true
            color: Qt.black
            text: tlCoordinateDecimal

            background: Rectangle {
                implicitWidth: 200
                implicitHeight: 40
                color: "transparent"
                // border.color: "black"
            }

            FontMetrics {
                id: fm2
                font: mouseCoordsDec.font
            }
        }

        TextField {
            id: mouseCoords
            Layout.preferredWidth: fm.boundingRect("00° 00' 00.0\" N, 00° 00' 00.0\" W, 0m").width + leftPadding + rightPadding;
            readOnly: true
            color: Qt.black
            text: mapBase.topLeftCoordinate.toString();

            background: Rectangle {
                implicitWidth: 200
                implicitHeight: 40
                color: "transparent"
                // border.color: "black"
            }

            FontMetrics {
                id: fm
                font: mouseCoords.font
            }
        }
    }
}
