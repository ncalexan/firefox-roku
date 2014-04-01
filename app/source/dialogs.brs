' This Source Code Form is subject to the terms of the Mozilla Public
' License, v. 2.0. If a copy of the MPL was not distributed with this file,
' You can obtain one at http://mozilla.org/MPL/2.0/.


function showMessage(title As dynamic, message As dynamic) As Object
    port = createObject("roMessagePort")
    dialog = createObject("roMessageDialog")
    dialog.setMessagePort(port)

    dialog.setTitle(title)
    dialog.setText(message)

    dialog.addButton(0, "Back")
    dialog.enableBackButton(true)

    dialog.show()

    while true
        dlgMsg = wait(0, dialog.getMessagePort())
        if type(dlgMsg) = "roMessageDialogEvent"
            if dlgMsg.isScreenClosed()
                dialog = invalid
                return 0
            else if dlgMsg.isButtonPressed()
                dialog = invalid
                return dlgMsg.getIndex()
            endif
        endif
    end while
end function


sub showBadVersion()
    port = createObject("roMessagePort")
    dialog = createObject("roMessageDialog")
    dialog.setMessagePort(port)
    dialog.setTitle("Connection Error")
    dialog.setText("Unable to connect to Firefox.")

    dialog.addButton(1, "Exit")
    dialog.enableBackButton(true)
    dialog.show()
    while true
        dlgMsg = wait(0, dialog.getMessagePort())
        if type(dlgMsg) = "roMessageDialogEvent"
            if dlgMsg.isButtonPressed()
                if dlgMsg.getIndex() = 1
                    exit while
                end if
            else if dlgMsg.isScreenClosed()
                exit while
            end if
        end if
    end while
end sub
