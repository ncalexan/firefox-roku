function playVideo(server as object, connection as object, args as dynamic) as object
    this = {
        server: server
        connection: connection
        port: createObject("roMessagePort")
        progress: 0 ' buffering progress
        position: 0 ' playback position (in seconds)
        status: "unknown"
        updateStatus: video_updateStatus
        canvas: createObject("roImageCanvas") ' overlay
        player: createObject("roVideoPlayer")
        paint: video_paint
        eventLoop: video_eventLoop
    }

    this.canvas.setMessagePort(this.port)
    this.canvas.setLayer(0, { Color: "#000000" })
    this.canvas.show()

    this.player.setMessagePort(this.port)

    ' Video setup
    print "video URL: "; args.url
    this.player.SetContentList([{
        Stream: { url: args.url }
        StreamFormat: "mp4"
    }])

    this.player.play()
    this.status = "unknown"

    result = this.eventLoop()
    print "video return: " result
    return result
end function

function video_updateStatus(status as string)
    m.status = status
    if m.server <> invalid and m.connection <> invalid then
        response = m.server.makeResponse(status)
        m.connection.sendStr(response)
    end if
end function

function video_eventLoop() as object
    while true
        event = wait(100, m.port)
        if type(event) = "roVideoPlayerEvent" then
            if event.isScreenClosed() then
                print "Closing video screen"
                return 0
            else if event.isStatusMessage() and event.GetMessage() = "startup progress" then
                progress% = event.GetIndex() / 10
                if m.progress < progress% then
                    m.progress = progress%
                    m.paint()
                end if
            else if event.isStreamStarted() then
                m.updateStatus("started")
                m.paint()
            else if event.isPaused() then
                m.updateStatus("paused")
                m.paint()
            else if event.isResumed() then
                m.updateStatus("started")
                m.paint()
            else if event.isFullResult() then
                m.updateStatus("completed")
            else if event.isRequestFailed() then
                m.updateStatus("failed")
                message = event.getMessage()
                code = event.getIndex()
                print "Play failed: "; code; " msg: "; message
                if message = "" then
                    if code = 0 then
                        message = "Network Error: server down or unresponsive, server is unreachable, network setup problem on the client."
                    else if code = -1 then
                        message = "HTTP Error: malformed headers or HTTP error result."
                    else if code = -2 then
                        message = "HTTP Error: Connection timed out."
                    else if code = -4 then
                        message = "Stream Error: no streams were specified to play."
                    else if code = -5 then
                        message = "Media Error: the media format is unknown or unsupported."
                    else
                        ' code -3 is also unknown error
                        message = "Unknown Error: Unable to play video."
                    end if
                endif
                message = message + chr(10) + "Code: (" + code.toStr() + ")"
                showMessage("Playback Error", message)
                return -1
            else
                print "Unknown event: "; event.getType(); " msg: "; event.getMessage()
            endif
        end if

        if type(event) = "roImageCanvasEvent" then
            if event.isRemoteKeyPressed() then
                index = event.getIndex()
                if index = 0 then '<BACK>
                    m.player.stop()
                    return 0
                else if index = 13 then '<PAUSE/PLAY>
                    if m.status = "paused" then
                        m.player.resume()
                    else
                        m.player.pause()
                    end if
                end if
            end if
        end if

        if m.server <> invalid then
            event = wait(100, m.server.port)
            if type(event) = "roSocketEvent" then
                closed = false
                if m.connection.getID() = event.getSocketID() and m.connection.isReadable() then
                    received = m.connection.receiveStr(2048)
                    print "received is " received
                    if len(received) > 0 then
                        params = parseJSON(received)
                        if params.type = "PLAY" and m.status = "paused" then
                            m.player.resume()
                        else if params.type = "STOP" and m.status = "started" then
                            m.player.pause()
                        end if
                    else if len(received) = 0 then
                        ' Client closed
                        closed = true
                    end if
                end if
                if closed or not m.connection.eOK() then
                    print "closing connection"
                    m.server.connections.delete(stri(m.connection.getID()))
                    m.connection.close()
                end if
            end if
        end if
    end while
    return 0
end function

sub video_paint()
    list = []
    color = "#00000000" ' fully transparent

    if m.progress < 100 then
        color = "#00a0a0a0"
        screen = m.canvas.GetCanvasRect()
        topBar% = (screen.h - 12) / 2
        leftBar% = (screen.w - 532) / 2
        progress_bar = {
            TargetRect: { x: leftBar%, y: topBar%, w: 532, h: 12 },
            url: "pkg:/images/loading_bar.png"
        }

        padding% = 20

        topLogo% = topBar% - (79 + padding%)
        leftLogo% = (screen.w - 81) / 2
        list.Push({
            TargetRect: { x: leftLogo%, y: topLogo%, w: 81, h: 79 },
            url: "pkg:/images/loading_logo.png"
        })

        topText% = topBar% + (12 + padding%)
        leftText% = (screen.w - 300) / 2
        list.Push({
            Text: "Loading..."
            TextAttrs: { font: "large", color: "#707070" }
            TargetRect: { x: leftText%, y: topText%, w: 300, h: 100 }
        })
        if m.progress > 0 and m.progress <= 13 then
            progress_bar.url = "pkg:/images/loading_bar_1.png"
        else if m.progress > 13 and m.progress <= 25 then
            progress_bar.url = "pkg:/images/loading_bar_2.png"
        else if m.progress > 25 and m.progress <= 38 then
            progress_bar.url = "pkg:/images/loading_bar_3.png"
        else if m.progress > 38 and m.progress <= 50 then
            progress_bar.url = "pkg:/images/loading_bar_4.png"
        else if m.progress > 50 and m.progress <= 63 then
            progress_bar.url = "pkg:/images/loading_bar_5.png"
        else if m.progress > 63 and m.progress <= 75 then
            progress_bar.url = "pkg:/images/loading_bar_6.png"
        else if m.progress > 75 and m.progress <= 88 then
            progress_bar.url = "pkg:/images/loading_bar_7.png"
        else
            progress_bar.url = "pkg:/images/loading_bar_8.png"
        end if
        list.Push(progress_bar)
    else if m.status = "paused" then
        print "Painting the paused text"
        color = "#80000000" ' semi-transparent black
        list.push({
            Text: "Paused"
            TextAttrs: { font: "huge" }
            TargetRect: m.canvas.GetCanvasRect()
        })
    end if

    ' Clear previous contents
    m.canvas.clearLayer(0)
    m.canvas.clearLayer(1)

    m.canvas.allowUpdates(false)
    m.canvas.setLayer(0, { Color: color, CompositionMode: "Source" })
    m.canvas.setLayer(1, list)
    m.canvas.allowUpdates(true)
end sub
