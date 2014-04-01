' This Source Code Form is subject to the terms of the Mozilla Public
' License, v. 2.0. If a copy of the MPL was not distributed with this file,
' You can obtain one at http://mozilla.org/MPL/2.0/.

function createHelp(server as object) as integer
    this = {
        port: createObject("roMessagePort")
        screen: createObject("roListScreen")
        content: help_getContentList()
        eventLoop: help_eventLoop
    }

    this.screen.setMessagePort(this.port)
    this.screen.setBreadcrumbText("Home", "Help & Settings")

    this.screen.setContent(this.content)
    this.screen.show()

    this.eventLoop()
end function

function help_eventLoop()
    while (true)
        event = wait(0, m.port)
        if type(event) = "roListScreenEvent" then
            if event.isRemoteKeyPressed() then
                if event.getIndex() = 0 then '<BACK>
                    m.screen.close()
                end if
            else if event.isListItemSelected() then
                if m.content[event.getIndex()].doesExist("action") then
                    m.content[event.getIndex()].action()
                end if
            else if event.isScreenClosed() then
                exit while
            endif
        endif
    end while
end function

function help_getContentList() as object
    list = [{
        Title: "Welcome",
        HDBackgroundImageUrl: "pkg:/images/introduction_hd.png",
        SDBackgroundImageUrl: "pkg:/images/introduction_sd.png",
        ShortDescriptionLine1: "Learn about how to use",
        ShortDescriptionLine2: "Learn1" + chr(10) + "Learn2" + chr(10) + "Learn3"
    },
    {
        Title: "Prepare your network",
        HDBackgroundImageUrl: "pkg:/images/intro_1.png",
        SDBackgroundImageUrl: "pkg:/images/intro_1.png",
        ShortDescriptionLine1: "Install Firefox and make sure it's on the same network as your Roku",
    },
    {
        Title: "Sending videos",
        HDBackgroundImageUrl: "pkg:/images/intro_2.png",
        SDBackgroundImageUrl: "pkg:/images/intro_2.png",
        ShortDescriptionLine1: "Long tap videos in Firefox to send them to your TV",
    },
    {
        Title: "Clear recent history",
        Action: help_clearHistory
    }]
    return list
end function

sub help_clearHistory()
    clearHistory()

    port = createObject("roMessagePort")
    dialog = createObject("roMessageDialog")
    dialog.setMessagePort(port)
    dialog.setTitle("Firefox")
    dialog.setText("Recent history has been cleared.")

    dialog.addButton(1, "Done")
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