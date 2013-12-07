' This Source Code Form is subject to the terms of the Mozilla Public
' License, v. 2.0. If a copy of the MPL was not distributed with this file,
' You can obtain one at http://mozilla.org/MPL/2.0/.

sub main(params as object)
    ' Create the external input system
    socketPort = createObject("roMessagePort")
    socketAddr = createObject("roSocketAddress")
    socketAddr.setPort(9191)
    socketServer = createObject("roStreamSocket")
    socketServer.setMessagePort(socketPort)
    socketServer.setAddress(socketAddr)
    socketServer.notifyReadable(true)
    socketServer.listen(4)
    if not socketServer.eOK()
        print "Error creating listen socket"
        stop
    end if

    connections = {}

    ' Setup the applicationtheme
    initTheme()

    ' Set opaque background
    screen = createObject("roListScreen")
    screenPort = createObject("roMessagePort")
    screen.setMessagePort(screenPort)

    screen.SetBreadcrumbText("Home", "")

    menuFunctions = [
        createIntroduction,
        createRecentHistory
    ]

    contentList = [
        {
            Title: "Introduction",
            ID: "1",
            HDBackgroundImageUrl: "pkg:/images/mm_icon_focus_hd.png",
            SDBackgroundImageUrl: "pkg:/images/mm_icon_focus_sd.png",            
            ShortDescriptionLine1: "Long tap on a video in Firefox for Android to send it to your TV!",
        },
        {
            Title: "Recent History",
            ID: "2",
            ShortDescriptionLine1: "There is no recent history",
        }
    ]
    screen.SetContent(contentList)
    screen.show()

    ' Wait until we get a command to load a video
    while true
        event = wait(100, socketServer.getMessagePort())
        if type(event) = "roSocketEvent" then
            changedID = event.getSocketID()
            if changedID = socketServer.getID() and socketServer.isReadable() then
                ' New
                newConnection = socketServer.accept()
                if newConnection = invalid then
                    print "accept failed"
                else
                    print "accepted new connection " changedID
                    newConnection.notifyReadable(true)
                    newConnection.setMessagePort(socketPort)
                    connections[stri(newConnection.getID())] = newConnection
                    newConnection.sendStr("connected")
                end if
            else
                ' Activity on an open connection
                connection = connections[stri(changedID)]
                closed = false
                if connection.isReadable() then
                    received = connection.receiveStr(2048)
                    print "received is " received
                    if len(received) > 0 then
                        params = parseJSON(received)
                        if params.type = "LOAD" then
                            print "Reading params: "; params.src
                            videoParams = createObject("roAssociativeArray")
                            videoParams.url = params.src
                            videoParams.title = params.title
                            displayVideo(socketServer.getMessagePort(), connection, videoParams)
                            exit while
                        end if
                        ' If we are unable to send, just drop data for now.
                        ' You could use notifywritable and buffer data, but that is
                        ' omitted for clarity.
                    else if received = 0 then
                        ' Client closed
                        closed = true
                    end if
                end if
                if closed or not connection.eOK() then
                    print "closing connection " changedID
                    connection.close()
                    connections.delete(stri(changedID))
                end if
            end if
        end if

        event = wait(100, screen.getMessagePort())
        if type(event) = "roListScreenEvent" then
            if event.isListItemFocused() then
                screen.setBreadcrumbText(contentList[event.getIndex()].Title, "")
            else if event.isListItemSelected() then
                menuFunctions[event.getIndex()]()
            endif      
        endif
    end while

    ' Close the server
    socketServer.close()
    for each id in connections
        connections[id].close()
    end for

    ' Close the app
    canvas.clearLayer(1)
    sleep(50)
end sub

function displayVideo(socketPort as object, connection as object, args as dynamic)
    videoPort = createObject("roMessagePort")
    video = createObject("roVideoScreen")
    video.setMessagePort(videoPort)

    ' Video setup
    ' TODO: Add failure mode handling
    bitrates = [0]    
    urls = []
    title = ""
    qualities = ["HD"]
    streamFormat = "mp4"
    print "video URL: "; args.url
    print "type: "; type(args.url)

    if type(args) = "roAssociativeArray"
        print "Checking args"
        if type(args.url) = "String" and args.url <> "" then
            'if instr(args.url, ".mp4?") > 0 then
            '    urls[0] = left(args.url, instr(args.url, "?") - 1)
            'else
                urls[0] = args.url
            'end if
        end if
        if type(args.streamFormat) = "String" and args.streamFormat <> "" then
            streamFormat = args.streamFormat
        end if
        if type(args.title) = "String" and args.title <> "" then
            title = args.title
        else 
            title = ""
        end if
    end if

    videoclip = createObject("roAssociativeArray")
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = urls
    videoclip.StreamQualities = qualities
    videoclip.StreamFormat = streamFormat
    videoclip.Title = title
    'print "srt = ";srt
    'if srt <> invalid and srt <> "" then
        'videoclip.SubtitleUrl = srt
    'end if
    
    video.setContent(videoclip)
    video.show()
    videoStatus = "unknown"

    while true
        event = wait(100, video.getMessagePort())
        if type(event) = "roVideoScreenEvent"
            if event.isScreenClosed() then
                print "Closing video screen"
                exit while
            else if event.isStreamStarted()
                videoStatus = "started"
                connection.sendStr(videoStatus)
            else if event.isPaused()
                videoStatus = "paused"
                connection.sendStr(videoStatus)
            else if event.isResumed()
                videoStatus = "started"
                connection.sendStr(videoStatus)
            else if event.isFullResult()
                videoStatus = "completed"
                connection.sendStr(videoStatus)
            else if event.isRequestFailed()
                videoStatus = "failed"
                connection.sendStr(videoStatus)
                print "Play failed: "; event.getMessage()
            else
                print "Unknown event: "; event.getType(); " msg: "; event.getMessage()
            endif
        end if

        event = wait(100, socketPort)
        if type(event) = "roSocketEvent" then
            closed = false
            if connection.getID() = event.getSocketID() and connection.isReadable() then
                received = connection.receiveStr(2048)
                print "received is " received
                if len(received) > 0 then
                    params = parseJSON(received)
                    if params.type = "PLAY" and videoStatus = "paused" then
                        video.resume()
                    else if params.type = "STOP" and videoStatus = "started" then
                        video.pause()
                    end if
                else if received = 0 then
                    ' Client closed
                    closed = true
                end if
            end if
            if closed or not connection.eOK() then
                print "closing connection " changedID
                connection.close()
                ' TODO
                'connections.delete(stri(changedID))
            end if
        end if
    end while
end function
