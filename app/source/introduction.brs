' This Source Code Form is subject to the terms of the Mozilla Public
' License, v. 2.0. If a copy of the MPL was not distributed with this file,
' You can obtain one at http://mozilla.org/MPL/2.0/.

function createIntroduction() as integer
    canvas = createObject("roImageCanvas")
    port = createObject("roMessagePort")
    canvas.setMessagePort(port)
    canvas.setLayer(0, { Color: "#FF000000", CompositionMode: "Source" })
    canvas.show()
    
    ' Make a landing page layer
    screen = canvas.getCanvasRect()
    items = [
        {
            Text: "Firefox for Roku",
            TextAttrs: {
                Color: "#FFCCCCCC",
                Font: "Large",
                HAlign: "HCenter",
                VAlign: "VCenter",
                Direction: "LeftToRight"
            },
            TargetRect: {
                x: 0,
                y: 0,
                w: screen.w,
                h: screen.h
            }
        }
    ]
    canvas.setLayer(1, items)

    while (true)
        event = wait(0, port)
        if type(event) = "roImageCanvasEvent" then
            if event.isRemoteKeyPressed() then
                if event.getIndex() = 2 then
                    canvas.close()
                end if
            else if event.isScreenClosed() then
                return -1
            endif
        endif
    end while
end function
