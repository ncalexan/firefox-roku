function playVideo(server as object, connection as object, args as dynamic) as void
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

    this.eventLoop()
end function

function video_updateStatus(status as string)
    m.status = status
    if m.server <> invalid and m.connection <> invalid then
        response = m.server.makeResponse(status)
        m.connection.sendStr(response)
    end if
end function

function video_eventLoop()
    while true
        event = wait(100, m.port)
        if type(event) = "roVideoPlayerEvent" then
            if event.isScreenClosed() then
                print "Closing video screen"
                exit while
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
                print "Play failed: "; event.getMessage()
            else
                print "Unknown event: "; event.getType(); " msg: "; event.getMessage()
            endif
        end if

        if type(event) = "roImageCanvasEvent" then
            if event.isRemoteKeyPressed() then
                index = event.getIndex()
                if index = 0 then '<BACK>
                    m.player.stop()
                    exit while
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
end function

sub video_paint()
    list = []
    color = "#00000000" ' fully transparent

    if m.status = "paused" then
        print "Painting the paused text"
        color = "#80000000" ' semi-transparent black
        list.push({
            Text: "Paused"
            TextAttrs: { font: "huge" }
            TargetRect: m.canvas.GetCanvasRect()
        })
    end if

    m.canvas.allowUpdates(false)
    m.canvas.SetLayer(0, { Color: color, CompositionMode: "Source" })
    m.canvas.SetLayer(1, list)
    m.canvas.allowUpdates(true)
end sub
