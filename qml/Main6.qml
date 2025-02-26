// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning
import minimal_map

ApplicationWindow {
    id: main
    width: Qt.platform.os == "android" ? Screen.width : 512
    height: Qt.platform.os == "android" ? Screen.height : 512
    visible: true
    //title: map.center + " zoom " + map.zoomLevel.toFixed(3)
    //       + " min " + map.minimumZoomLevel + " max " + map.maximumZoomLevel

    property var currentMap: null
    property var mapTypes: [ "cycle",  "transport", "landscape", "outdoors", "transport-dark", "spinal-map", "pioneer", "mobile-atlas", "neighbourhood", "atlas" ]

    Component.onCompleted: {
        console.log("Map plugin API key: " + AppConfig.thunderforestApiKey);
        // createMap();
    }

    function createMap() {
        mapLoader.sourceComponent = null
        mapLoadTimer.start()
        // if(currentMap !== null) {
        //     console.log("Destroying existing map");
        //     currentMap.destroy();
        // }
        // console.log("Creating map");
        // currentMap = mapComponent.createObject(main, { z: -1 });
        // mapChoice.z = 10;
    }

    Timer {
        id: mapLoadTimer
        running: true
        interval: 500
        repeat: false
        onTriggered: {
            mapLoader.sourceComponent = mapComponent
        }
    }

    Loader {
        id: mapLoader
        anchors.fill: parent
        // sourceComponent: mapComponent
    }

    Component {
        id: mapComponent
        Item {
            anchors.fill: parent
            Plugin {
                id: mapPlugin
                property string mapType: mapTypes[mapChoice.currentIndex]
                onMapTypeChanged: console.log("Map type changed to " + mapType)
                name: "osm"
                // PluginParameter {
                //     name: "osm.mapping.providersrepository.address"
                //     value: "http://localhost:8080/"
                // }

                PluginParameter {
                    name: "osm.mapping.custom.host"
                    // "%z/%x/%y.png" will be automatically appended to the URL.
                    // Since Qt 6.5, if the URL already ends with .png, it will not be added.
                    value: "https://tile.thunderforest.com/" + mapTypes[mapChoice.currentIndex] + "/%z/%x/%y.png?apikey=" + AppConfig.thunderforestApiKey + "&fake="
                    onValueChanged: console.log("osm.mapping.custom.host: " + value)
                }
            }
            Map {
                id: map
                z: 5
                anchors.fill: parent
                plugin: mapPlugin
                center: QtPositioning.coordinate(43,-71.45) // Manchester, NH
                zoomLevel: 14
                property geoCoordinate startCentroid
                activeMapType: supportedMapTypes[supportedMapTypes.length-1]
                // activeMapType: supportedMapTypes[mapChoice.currentIndex]

                PinchHandler {
                    id: pinch
                    target: null
                    onActiveChanged: if (active) {
                        map.startCentroid = map.toCoordinate(pinch.centroid.position, false)
                    }
                    onScaleChanged: (delta) => {
                        map.zoomLevel += Math.log2(delta)
                        map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
                    }
                    onRotationChanged: (delta) => {
                        map.bearing -= delta
                        map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
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
                    onTranslationChanged: (delta) => map.pan(-delta.x, -delta.y)
                }
                Shortcut {
                    enabled: map.zoomLevel < map.maximumZoomLevel
                    sequence: StandardKey.ZoomIn
                    onActivated: map.zoomLevel = Math.round(map.zoomLevel + 1)
                }
                Shortcut {
                    enabled: map.zoomLevel > map.minimumZoomLevel
                    sequence: StandardKey.ZoomOut
                    onActivated: map.zoomLevel = Math.round(map.zoomLevel - 1)
                }
            }
        }
    }

    ComboBox {
        id: mapChoice
        z: 10
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10
        model: main.mapTypes
        currentIndex: 0
        onActivated: (index) => {
            createMap();
        }
    }
}
