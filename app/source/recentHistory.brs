' This Source Code Form is subject to the terms of the Mozilla Public
' License, v. 2.0. If a copy of the MPL was not distributed with this file,
' You can obtain one at http://mozilla.org/MPL/2.0/.

function createRecentHistory(server as object) as integer
    this = {
        port: createObject("roMessagePort")
        screen: createObject("roGridScreen")
        content: getContentList_main()
        eventLoop: eventLoop_history
    }

    this.screen.setMessagePort(this.port)

    ' Set up the grid before calling setupLists()
    this.screen.setBreadcrumbText("Home", "Recent History")
    this.screen.setUpBehaviorAtTopRow("exit")
    this.screen.setDisplayMode("scale-to-fill")
    this.screen.setGridStyle("two-row-flat-landscape-custom")

    this.screen.setupLists(2)
    this.screen.setListNames(["History", "About Mozilla & Firefox"])

    this.screen.setContentList(0, getRecentList())
    this.screen.setContentList(1, getDefaultList())

    ' Must be called after setupLists()
    this.screen.setDescriptionVisible(false)

    this.screen.show()

    this.eventLoop(server)
end function

function eventLoop_history(server as object)
    while (true)
        server.processEvents()

        event = wait(0, m.screen.getMessagePort())
        if type(event) = "roGridScreenEvent" then
            print "msg= "; event.GetMessage() " , index= "; event.GetIndex(); " data= "; event.getData()
            if event.isListItemFocused() then
                print "list item focused | current show = "; event.GetIndex()
            else if event.isListItemSelected() then
                row = event.GetIndex()
                selection = event.getData()
                print "list item selected row= "; row; " selection= "; selection
            else if event.isScreenClosed() then
                return -1
            end if
        end if
    end while
end function

function getRecentList() as object
    list = []
    json = registryRead("history")
    if json <> invalid then
        history = parseJSON(json)
        for each video in history
            list.push({
                Title: video.title
                Description: video.description
                HDPosterUrl: video.poster
                SDPosterUrl: video.poster
                VideoUrl: video.url
            })
        end for
        return list
    end if

    ' Add an empty placeholder
    list.push({
        Title: "No Recent Videos"
        Description: "Watch some videos!"
        HDPosterUrl: "pkg://images/fruit.jpg"
        SDPosterUrl: "pkg://images/fruit.jpg"
    })
   return list
end function

function getDefaultList() as object
    jsonAsString = readAsciiFile("pkg:/json/defaults.json")
    history = parseJSON(jsonAsString)
    list = []
    for each video in history
        list.Push({
            Title: video.title
            Description: video.description
            HDPosterUrl: video.poster
            SDPosterUrl: video.poster
            VideoUrl: video.url
        })
    end for
    return list
end function

sub saveToHistory(args as dynamic)
    print args.url
    history = []
    json = registryRead("history")
    if json <> invalid then
        print json
        history = parseJSON(json)
        if history = invalid then
            history = []
        end if
    end if

    history.push({
        title: args.title
        description: "Empty"
        poster: args.poster
        url: args.url
    })

    if history.count() > 10 then
        history.shift()
    end if

    ' TODO: Remove duplicates

    json = toJSON(history)
    print json
    registryWrite("history", json)
end sub
