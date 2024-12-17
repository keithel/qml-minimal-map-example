# minimal-map Example for Qt 6.5+ and Qt 5.15

This provides the Qt minimal-map example unified for both Qt 5.15 and Qt 6,
built using CMake, even for Qt 5.

It provides some best practices for writing CMake projects that are compatible
with both Qt 5 and Qt 6.

## Qt 6

For Qt 6, this builds a QML module, which is loaded into the QML engine using
`engine.loadFromModule`.

## Qt 5

For Qt 5, this packages the QML in a Qt Resource file, packaged with the
application. It loads the QML using the Qt resource system.
