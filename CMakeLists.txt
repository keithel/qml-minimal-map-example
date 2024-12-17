# Generated from minimal_map.pro.

cmake_minimum_required(VERSION 3.16)
project(minimal_map VERSION 0.1 LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

if(NOT DEFINED INSTALL_EXAMPLESDIR)
    set(INSTALL_EXAMPLESDIR "examples")
endif()

set(INSTALL_EXAMPLEDIR "${INSTALL_EXAMPLESDIR}/location/${PROJECT_NAME}")

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Gui QuickControls2 Location Qml)

set(PROJECT_SOURCES
    main.cpp
)

set(qml_module_uri com.example.${PROJECT_NAME})

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_policy(SET QTP0001 NEW)
    qt_policy(SET QTP0004 NEW)

    qt_add_executable(${PROJECT_NAME} WIN32 MACOSX_BUNDLE
        ${PROJECT_SOURCES}
    )

    qt_add_qml_module(${PROJECT_NAME}
        URI ${qml_module_uri}
        VERSION 1.0
        QML_FILES
            "qml/Main6.qml"
        #RESOURCES
            # List relative path to resources here
    )

    # This is so that in C++, you can provide path to resources without hardcoding the resource
    # prefix. It's possible this may be able to be created just from within C++ - as you probably
    # can get the module URI, then do the .->/ replacement in C++, so I guess this is the lazy
    # approach.
    string(REPLACE "." "/" qml_module_resource_path "${qml_module_uri}/")
    target_compile_definitions(${PROJECT_NAME} PRIVATE
        RESOURCE_PREFIX="${qml_module_resource_path}"
    )
else()
    list(APPEND PROJECT_SOURCES "qml.qrc")
    add_executable(${PROJECT_NAME}
        ${PROJECT_SOURCES}
    )
endif()

target_link_libraries(${PROJECT_NAME} PUBLIC
    Qt::Core
    Qt::Gui
    Qt::QuickControls2
    Qt::Location
    Qt::Qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
if(${QT_VERSION} VERSION_LESS 6.1.0)
  set(BUNDLE_ID_OPTION MACOSX_BUNDLE_GUI_IDENTIFIER ${qml_module_uri})
endif()

set_target_properties(${PROJECT_NAME} PROPERTIES
    ${BUNDLE_ID_OPTION}
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION "${INSTALL_EXAMPLEDIR}"
    BUNDLE DESTINATION "${INSTALL_EXAMPLEDIR}"
    LIBRARY DESTINATION "${INSTALL_EXAMPLEDIR}"
)
