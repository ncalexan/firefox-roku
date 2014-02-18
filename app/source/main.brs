' This Source Code Form is subject to the terms of the Mozilla Public
' License, v. 2.0. If a copy of the MPL was not distributed with this file,
' You can obtain one at http://mozilla.org/MPL/2.0/.

sub main(params as object)
    this = {
        port: createObject("roMessagePort")
        screen: createObject("roListScreen")
        content: main_getContentList()
        eventLoop: main_eventLoop
    }

    server = setupServer()

    ' Setup the applicationtheme
    initTheme()

    ' Set opaque background
    this.screen.setMessagePort(this.port)
    this.screen.setBreadcrumbText("Home", "")

    this.screen.setContent(this.content)

    ' Only show the main screen if we were launched via home screen
    if params = invalid then
        this.screen.show()
    else
        version = params.remote
        if version <> server.protocolVersion then
            showBadVersion()
        end if
    end if

    this.eventLoop(server)

    ' Close the server
    server.close()

    ' Close the app
    sleep(50)
end sub

function main_eventLoop(server as object)
    while true
        server.processEvents()

        event = wait(100, m.screen.getMessagePort())
        if type(event) = "roListScreenEvent" then
            if event.isListItemFocused() then
                m.screen.setBreadcrumbText(m.content[event.getIndex()].Title, "")
            else if event.isListItemSelected() then
                m.content[event.getIndex()].handler(server)
            end if
        end if
    end while
end function

function main_getContentList() as object
    list = [{
        Title: "Introduction",
        ID: "1",
        HDBackgroundImageUrl: "pkg:/images/android-phone-tablet.png",
        SDBackgroundImageUrl: "pkg:/images/android-phone-tablet.png",
        ShortDescriptionLine1: "Long tap on a video in Firefox for Android to send it to your TV!",
        Handler: createIntroduction
    },
    {
        Title: "Recent History",
        ID: "2",
        ShortDescriptionLine1: "There is no recent history",
        Handler: createRecentHistory
    }]
    return list
end function

function showBadVersion() as void
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
end function
