' This Source Code Form is subject to the terms of the Mozilla Public
' License, v. 2.0. If a copy of the MPL was not distributed with this file,
' You can obtain one at http://mozilla.org/MPL/2.0/.

function createRecentHistory(server as object) as integer
    this = {
        port: createObject("roMessagePort")
        screen: createObject("roGridScreen")
        history: []
        eventLoop: history_eventLoop
    }

    this.screen.setMessagePort(this.port)

    ' Set up the grid before calling setupLists()
    this.screen.setBreadcrumbText("Home", "Recent History")
    this.screen.setUpBehaviorAtTopRow("exit")
    this.screen.setDisplayMode("scale-to-fill")
    this.screen.setGridStyle("two-row-flat-landscape-custom")

    this.screen.setupLists(2)
    this.screen.setListNames(["History", "About Mozilla & Firefox"])

    this.history[0] = getRecentHistory()
    this.history[1] = getDefaultHistory()
    this.screen.setContentList(0, this.history[0])
    this.screen.setContentList(1, this.history[1])

    ' Must be called after setupLists()
    this.screen.setDescriptionVisible(false)

    this.screen.show()

    this.eventLoop(server)
end function

function history_eventLoop(server as object)
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
                videoParams = {
                    url: m.history[row][selection].VideoURL
                }

                playVideo(invalid, invalid, videoParams)
            else if event.isScreenClosed() then
                return -1
            end if
        end if
    end while
end function

' Global utilities for reading and saving history

function getRecentHistory() as object
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

function getDefaultHistory() as object
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

    ' If an existing entry is already in history, return without saving
    for each item in history
        if item.url = args.url then
            return
        end if
    end for

    history.push({
        title: args.title
        description: "Empty"
        poster: args.poster
        url: args.url
    })

    if history.count() > 10 then
        history.shift()
    end if

    json = toJSON(history)
    print json
    registryWrite("history", json)
end sub
