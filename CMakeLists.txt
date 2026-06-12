cmake_minimum_required(VERSION 3.16)

project(FormulaDash VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick SerialPort)

qt_standard_project_setup()

qt_add_executable(appFormulaDash
    main.cpp
)

qt_add_qml_module(appFormulaDash
    URI FormulaDash
    VERSION 1.0
    QML_FILES
        Main.qml
        DriverPage.qml
        DiagnosticPage.qml
        MissionSelectionPage.qml
        ActiveMissionPage.qml
    SOURCES
        vehicledataprovider.h
        vehicledataprovider.cpp
    RESOURCES
        assets/aristurtle_logo.png

        assets/team_logo_right.png

        assets/background_bold_1.png
        assets/radio_off.png
        assets/radio_on.png
        assets/cooling_off.png
        assets/cooling_on.png
        assets/battery_0.png
        assets/battery_1.png
        assets/battery_2.png
        assets/battery_3.png
        assets/battery_4.png
        assets/battery_5.png
        assets/battery_6.png
        assets/tc_off.png
        assets/tc_on.png
        assets/accumulator_voltage_normal.png
        assets/accumulator_voltage_warning.png
        assets/regen_off.png
        assets/regen_on.png
        assets/torque_vectoring_off.png
        assets/torque_vectoring_on.png
        assets/sideslip_off.png
        assets/sideslip_on.png
        assets/topdown.png

)
# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appFormulaDash PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appFormulaDash
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appFormulaDash PRIVATE Qt6::Quick Qt6::SerialPort)

include(GNUInstallDirs)
install(TARGETS appFormulaDash
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
