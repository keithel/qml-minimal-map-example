# minimal-map-thunderforest Example for Qt 6.5+ with image overlay

This provides a minimal map example with external map tile source provider
Thunderforest. It is based on the Qt minimal-map example shipped with Qt.

It also illustrates how to overlay an image at a particular set of
coordinates and zoom level using a MapQuickItem

## Prerequisites

 * A compiler supported by Qt
 * CMake version 3.16+
 * A Qt 6.5+ installation (for best results, get from qt.io) with the following
   modules installed:
    * Qt HTTP Server
    * Qt Location
    * Qt Multimedia
    * Qt Positioning
 * A [Thunderforest account](https://www.thunderforest.com/pricing/) ([basic free tier](https://manage.thunderforest.com/users/sign_up?price=hobby-project-usd) is fine)
   * The API Key from the [dashboard](https://manage.thunderforest.com/dashboard) of your Thunderforest account

## Running the example

After building, run the example with the command line argument `-k <API key>`, substituting your API key in place of `<API key>`.
