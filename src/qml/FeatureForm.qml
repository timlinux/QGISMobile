/***************************************************************************
                            FeatureForm.qml
                              -------------------
              begin                : 10.12.2014
              copyright            : (C) 2014 by Matthias Kuhn
              email                : matthias.kuhn (at) opengis.ch
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import org.qgis 1.0

Rectangle {
  id: featureForm

  property FeatureListModelSelection selection
  property MapSettings mapSettings
  property color selectionColor

  states: [
    State {
      name: "Hidden"
      StateChangeScript {
        script: hide()
      }
    },
    /* Shows a list of features */
    State {
      name: "FeatureList"
      PropertyChanges {
        target: globalFeaturesList
        shown: true
      }
      PropertyChanges {
        target: featureListToolBar
        state: "Indication"
      }
      StateChangeScript {
        script: show()
      }
    },
    /* Shows the form for the currently selected feature */
    State {
      name: "FeatureForm"
      PropertyChanges {
        target: globalFeaturesList
        shown: false
      }
      PropertyChanges {
        target: featureListToolBar
        state: "Navigation"
      }
    },
    /* Shows an edibale form for the currently selected feature */
    State {
      name: "FeatureFormEdit"
      PropertyChanges {
        target: featureListToolBar
        state: "Edit"
      }
      PropertyChanges {
        target: featureFormList
        state: "Edit"
      }
    }

  ]
  state: "Hidden"

  focus: ( state != "Hidden" )

  clip: true

  ListView {
    id: globalFeaturesList

    anchors.top: featureListToolBar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: parent.height - featureListToolBar.height

    property bool shown: false

    clip: true

    model: featureListModel
    section.property: "layerName"
    section.labelPositioning: ViewSection.CurrentLabelAtStart | ViewSection.InlineLabels
    section.delegate: Component {
      /* section header: layer name */
      Rectangle {
        width: parent.width
        height: 30*dp
        color: "lightGray"

        Text {
          anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
          font.bold: true
          text: section
        }
      }
    }

    delegate: Item {
      anchors { left: parent.left; right: parent.right }

      focus: true

      height: Math.max( 48*dp, featureText.height )

      Text {
        id: featureText
        anchors { leftMargin: 10; left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        font.bold: true
        text: display
      }

      Rectangle {
        anchors.left: parent.left
        height: parent.height
        width: 6
        color: featureForm.selectionColor
        opacity: ( index == featureForm.selection.selection )
        Behavior on opacity {
          PropertyAnimation {
            easing.type: Easing.InQuart
          }
        }
      }

      /* bottom border */
      Rectangle {
        anchors.bottom: parent.bottom
        height: 1
        color: "lightGray"
        width: parent.width
      }

      MouseArea {
        anchors.fill: parent

        onClicked: {
          featureForm.selection.selection = index
          featureForm.state = "FeatureForm"
        }

        onPressAndHold:
        {
          featureForm.selection.selection = index
        }
      }
    }

    /* bottom border */
    Rectangle {
      anchors.bottom: parent.bottom
      height: 1
      color: "lightGray"
      width: parent.width
    }

    onShownChanged: {
      if ( shown )
      {
        height = parent.height - featureListToolBar.height
      }
      else
      {
        height = 0
      }
    }

    Behavior on height {
      PropertyAnimation {
        easing.type: Easing.InQuart
      }
    }
  }

  ListView {
    id: featureFormList

    states: [
      State {
        name: "ReadOnly"
      },
      State {
        name: "Edit"
      }
    ]

    anchors.top: featureListToolBar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: parent.height - globalFeaturesList.height

    model: FeatureModel {
      feature: featureForm.selection.selectedFeature
    }

    focus: true

    visible: (!globalFeaturesList.shown)

    delegate: Item {
      anchors.left: parent.left
      anchors.right: parent.right
      height: childrenRect.height

      Rectangle {
        anchors { right: parent.right; left: parent.left }
        height: Math.max( 30*dp, childrenRect.height )

        Item {
          anchors { verticalCenter: parent.verticalCenter; right: parent.right; left:parent.left }
          height: childrenRect.height

          /* attribute name */
          Text {
            id: txtAttributeName
            anchors.leftMargin: 5
            width: featureFormList.width / 3
            font.bold: true
            text: attributeName
            clip: true
          }

          Item {
            anchors { leftMargin: 5; right: parent.right; left: txtAttributeName.right }
            height: childrenRect.height

            /* attribute value */
            Loader {
              id: attributeEditorLoader
              anchors { left: parent.left; right: parent.right }

              visible: featureFormList.state == "Edit"
              property variant value: attributeValue
              property variant config: editorWidgetConfig

              source: 'editorwidgets/' + editorWidget + '.qml'
            }

            Connections {
              target: attributeEditorLoader.item
              onValueChanged: featureFormList.model.setData( index, value, FeatureModel.AttributeValue )
            }

            Text {
              visible: featureFormList.state != "Edit"
              text: attributeValue
            }
          }
        }

        /* Bottom border */
        Rectangle {
          height: 1
          color: "lightGray"
          width: parent.width
          anchors.bottom: parent.bottom
        }
      }
    }
  }

  NavigationBar {
    id: featureListToolBar
    model: featureListModel
    selection: featureForm.selection
    extentController: FeaturelistExtentController {
      model: featureListModel
      selection: featureForm.selection
      mapSettings: featureForm.mapSettings
    }

    onStatusIndicatorClicked: {
      featureForm.state = "FeatureList"
    }

    onEditButtonClicked: {
      featureForm.state = "FeatureFormEdit"
    }

    onSave: {
      featureFormList.model.save()
      featureForm.state = "FeatureForm"
    }

    onCancel: {
      featureFormList.model.reset()
      featureForm.state = "FeatureForm"
    }
  }

  Keys.onReleased: {
    if (event.key === Qt.Key_Back) {
      state = "Hidden"
      event.accepted = true
    }
  }

  Behavior on width {
    PropertyAnimation {
      easing.type: Easing.InQuart
    }
  }

  Connections {
    target: featureListModel

    onModelReset: {
      state = "FeatureList"
    }
  }

  function show()
  {
    var widthDenominator = settings.value( "featureForm/widthDenominator", 3 );
    width = parent.width / widthDenominator
    // Focus to retrieve back button events
    focus = true
  }

  function hide()
  {
    width = 0
    focus = false
  }
}
