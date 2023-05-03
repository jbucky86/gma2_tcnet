  -- Import required libraries
local socket = require("socket/socket")
local udp = socket.udp()
local udp2 = socket.udp()
local udpSwtc = 1
local ethernetPOrtNum = 0

-- Constants
local BROADCAST_IP = ""
local OPTIN_PORT = 60000
local TCNet_TIME_PORT = 60001
local NO_DOCS_PORT = 60002
local GMA_PORT = 60250
local nodes = {}
local firstMasterNodeName = nil
local lastSeq = nil
local prevOptInData = {}
local prevOptOutData = {}
local prevStatusData = {}
local prevTimeSyncData = {}
local prevErrorData = {}
local prevControlData = {}
local prevTextData = {}
local prevKeyboardData = {}
local prevDataDataMetrics = {}
local prevMetadataData = {}
local prevBeatGridData = {}
local prevLayersCueData = {}
local layerNamesCue = { "1", "2", "3", "4", "A", "B", "M", "C" }
local prevSMPTEData = {}


local function SKupdater(prevData, Data)
    -- Compare the new values with the previous values and print if there is a change
    for key, value in pairs(Data) do
        if prevData[key] ~= value then
---------------------------------------------------Add Commands under here ----------------------------------------------------------
            --gma.cmd("")
            gma.echo(key .. ": " .. tostring(value))
        end
    end

    -- Update the previous Opt-IN data with the new values
    prevData = Data
    return prevData
end


-- Internal timer
local function timer()
    return math.floor(socket.gettime() * 1000000 % 1000000)
end

-- Create a header for TCNet messages
local function createHeader(nodeID, protocolVersionMajor, protocolVersionMinor, messageType, nodeName, seq, nodeType, nodeOptions, timestamp)
    local header = string.pack("<HBB",
        nodeID,
        protocolVersionMajor,
        protocolVersionMinor) ..
        'TCN' ..
        string.pack("<B", messageType) ..
        nodeName ..
        string.pack("<BBH",
        seq,
        nodeType,
        nodeOptions
    )
    return header .. string.pack("<I", timestamp)
end

-- Create a TCNet GW Opt-IN message
local function createOptInMessage(header, nodeCount, nodeListenerPort, uptime, vendorName, deviceName, deviceMajorVersion, deviceMinorVersion, deviceBugVersion)
    local optInMessage = header .. string.pack("<HHHH",
        nodeCount,
        nodeListenerPort,
        uptime,
        0) ..
        vendorName ..
        deviceName ..
        string.pack("<BBBB",
        deviceMajorVersion,
        deviceMinorVersion,
        deviceBugVersion,
        0
    )
    return optInMessage
end

local function SKupdater(prevData, Data, mesType)
    -- Compare the new values with the previous values and print if there is a change
    for key, value in pairs(Data) do
        if prevData[key] ~= value then

            gma.echo(key .. ": " .. tostring(value))
        end
    end

    -- Update the previous Opt-IN data with the new values
    prevData = Data
    return prevData
end

-- Send TCNet GW Opt-IN package
local function sendOptInPackage(udp, header)
    -- Add basic information and functionality of the node
    local optInMessage = createOptInMessage(header, 1, GMA_PORT, 100, "BUCKYS GMA LUA  ", "TCnet for GMA2  ", 0, 0, 3)
    udp:sendto(optInMessage, BROADCAST_IP, OPTIN_PORT)
end

local function handleHeader(data)
    local header = {}
    header.nodeID, header.protocolVersionMajor, header.protocolVersionMinor, header.tcnetHeader,
    header.messageType, header.nodeName, header.seq, header.nodeType, header.nodeOptions,
    header.timestamp = string.unpack("<HBBc3Bc8BBH<I", data)
    return header
end

local function handleOptIn(data, node, megType)
    if data == nil or #data < 67 or #data > 68 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    local optInData = {}
    optInData.nodeCount,
    optInData.nodeListenerPort,
    optInData.uptime,
    optInData.reserved1,
    optInData.vendorName,
    optInData.deviceName,
    optInData.deviceMajorVersion,
    optInData.deviceMinorVersion,
    optInData.deviceBugVersion,
    optInData.reserved2 = string.unpack("<HHHHc16c16BBBB", data:sub(25))
    prevOptInData = SKupdater(prevOptInData, optInData, megType)
end

local function handleOptOut(data, node, megType)
    if data == nil or #data < 27 or #data > 28 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet OPT-OUT message
    local optOutData = {}
    optOutData.nodeCount,
    optOutData.nodeListenerPort = string.unpack("<HH", data:sub(25))
    prevOptOutData = SKupdater(prevOptOutData, optOutData, megType)
end

local function handleStatus(data, node, megType)
    if data == nil or #data < 299  or #data > 300 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet STATUS message
    local statusData = {}
    statusData.nodeCount,
    statusData.nodeListenerPort,
    statusData.reserved1,
    statusData.layer1Source,
    statusData.layer2Source,
    statusData.layer3Source,
    statusData.layer4Source,
    statusData.layerASource,
    statusData.layerBSource,
    statusData.layerMSource,
    statusData.layerCSource,
    statusData.layer1Status,
    statusData.layer2Status,
    statusData.layer3Status,
    statusData.layer4Status,
    statusData.layerAStatus,
    statusData.layerBStatus,
    statusData.layerMStatus,
    statusData.layerCStatus,
    statusData.layer1TrackID,
    statusData.layer2TrackID,
    statusData.layer3TrackID,
    statusData.layer4TrackID,
    statusData.layerATrackID,
    statusData.layerBTrackID,
    statusData.layerMTrackID,
    statusData.layerCTrackID,
    statusData.reserved2,
    statusData.smpteMode,
    statusData.autoMasterMode,
    statusData.reserved3,
    statusData.appSpecific,
    statusData.layer1Name,
    statusData.layer2Name,
    statusData.layer3Name,
    statusData.layer4Name,
    statusData.layerAName,
    statusData.layerBName,
    statusData.layerMName,
    statusData.layerCName = string.unpack("<HHc6BBBBBBBBBBBBBBBBI4I4I4I4I4I4I4I4BBBc15BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", data:sub(25))
    prevStatusData = SKupdater(prevStatusData,  statusData, megType)
end

local function handleTimeSync(data, node, megType)
    if data == nil or #data < 31  or #data > 32 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet TimeSync message
    local timeSyncData = {}
    timeSyncData.step,
    timeSyncData.reserved,
    timeSyncData.nodeListenerPort,
    timeSyncData.remoteTimestamp = string.unpack("<Bc1HI4", data:sub(25))
    prevTimeSyncData = SKupdater(prevTimeSyncData,  timeSyncData, megType)
end

local function handleError(data, node, megType)
    if data == nil or #data < 29  or #data > 30 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet ERROR message
    local errorData = {}
    errorData.datatype,
    errorData.layerID,
    errorData.code,
    errorData.messageType = string.unpack("<BBHH", data:sub(25))
    prevErrorData = SKupdater(prevTimeSyncData,  errorData, megType)
end

local function handleRequest(data, node, megType)
    if data == nil or #data < 25 or #data > 29 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet REQUEST message
    local requestData = {}
    requestData.dataType,
    requestData.layer = string.unpack("<BB", data:sub(25))
    prevRequestData = SKupdater(prevRequestData, requestData, megType)
end

local function handleControl(data, node, megType)
    if data == nil or #data < 41  or #data > 42 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet CONTROL message
    local controlData = {}
    controlData.step,
    controlData.reserved1,
    controlData.dataSize,
    controlData.reserved2,
    controlData.controlPath = string.unpack("<Bc1I<c12c" .. controlData.dataSize, data:sub(25))
    prevControlData = SKupdater(prevControlData, controlData, megType)
end

local function handleText(data, node, megType)
    if data == nil or #data < 42  or #data > 43 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet TEXT message
    local textData = {}
    textData.step,
    textData.reserved1,
    textData.dataSize,
    textData.reserved2,
    textData.textData = string.unpack("<Bc1I<c12c" .. textData.dataSize, data:sub(25))
    prevTextData = SKupdater(prevTextData, textData, megType)
end

local function handleKeyboard(data, node, megType)
    if data == nil or #data < 43 or #data > 44 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet KEYBOARD message
    local keyboardData = {}
    keyboardData.reserved1,
    keyboardData.reserved2,
    keyboardData.dataSize,
    keyboardData.reserved3,
    keyboardData.keyboardData = string.unpack("<ccIc12H", data:sub(25))
    prevKeyboardData = SKupdater(prevKeyboardData, keyboardData, megType)
end

local function handleDataMetrics(data, node, megType)
    if data == nil or #data < 122 or #data > 123 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet DATA message
    local dataData = {}
    dataData.dataType,
    dataData.layerID,
    dataData.reserved1,
    dataData.layerState,
    dataData.reserved2,
    dataData.syncMaster,
    dataData.reserved3,
    dataData.beatMarker,
    dataData.trackLength,
    dataData.currentPosition,
    dataData.speed,
    dataData.reserved4,
    dataData.beatNumber,
    dataData.reserved5,
    dataData.bpm,
    dataData.pitchBend,
    dataData.trackID = string.unpack("<BBBBBBBBI4I4I4c13I4c51I4H4", data:sub(25))
    prevDataMetrics = SKupdater(prevDataMetrics, dataData, megType)
end

local function handleMetadata(data, node, megType)
    if data == nil or #data < 547  or #data > 548 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet METADATA message
    local metadataData = {}
    metadataData.dataType,
    metadataData.layerID,
    metadataData.reserved1,
    metadataData.reserved2,
    metadataData.trackArtist,
    metadataData.trackTitle,
    metadataData.trackKey,
    metadataData.trackID = string.unpack("<BBBBc128c128HI4", data:sub(25))
    prevMetadataData = SKupdater(prevMetadataData, metadataData, megType)
end

local function handleBeatGrid(data, node, megType)
    if data == nil or #data < 2441  or #data > 2442 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet BEAT GRID message
    local beatGridData = {}
    beatGridData.dataType,
    beatGridData.layerID,
    beatGridData.reserved1,
    beatGridData.reserved2,
    beatGridData.trackArtist,
    beatGridData.trackTitle,
    beatGridData.trackKey,
    beatGridData.trackID = string.unpack("<c1Bc1<c2c128c128HI4", data:sub(25))
    prevBeatGridData = SKupdater(prevBeatGridData , beatGridData, megType)
end

local function handleSMPTETime(data, node, megType)
    if data == nil or #data < 161 or #data > 162 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    -- Process TCNet SMPTE Time message
    local smpteData = {}
    smpteData.L1Time, smpteData.L2Time, smpteData.L3Time, smpteData.L4Time,
    smpteData.LATime, smpteData.LBTime, smpteData.LMTime, smpteData.LCTime,
    smpteData.L1TotalTime, smpteData.L2TotalTime, smpteData.L3TotalTime, smpteData.L4TotalTime,
    smpteData.LATotalTime, smpteData.LBTotalTime, smpteData.LMTotalTime, smpteData.LCTotalTime,
    smpteData.L1BeatMarker, smpteData.L2BeatMarker, smpteData.L3BeatMarker, smpteData.L4BeatMarker,
    smpteData.LABeatMarker, smpteData.LBBeatMarker, smpteData.LMBeatMarker, smpteData.LCBeatMarker,
    smpteData.L1LayerState, smpteData.L2LayerState, smpteData.L3LayerState, smpteData.L4LayerState,
    smpteData.LALayerState, smpteData.LBLayerState, smpteData.LMLayerState, smpteData.LCLayerState,
    smpteData.reserved, smpteData.SMPTEMode, smpteData.L1SMPTEMode, smpteData.L1TimeCodeState,
    smpteData.L1TimeCodeHours, smpteData.L1TimeCodeMinutes, smpteData.L1TimeCodeSeconds, smpteData.L1TimeCodeFrames,
    smpteData.L2SMPTEMode, smpteData.L2TimeCodeState, smpteData.L2TimeCodeHours, smpteData.L2TimeCodeMinutes,
    smpteData.L2TimeCodeSeconds, smpteData.L2TimeCodeFrames, smpteData.L3SMPTEMode, smpteData.L3TimeCodeState,
    smpteData.L3TimeCodeHours, smpteData.L3TimeCodeMinutes, smpteData.L3TimeCodeSeconds, smpteData.L3TimeCodeFrames,
    smpteData.L4SMPTEMode, smpteData.L4TimeCodeState, smpteData.L4TimeCodeHours, smpteData.L4TimeCodeMinutes,
    smpteData.L4TimeCodeSeconds, smpteData.L4TimeCodeFrames = string.unpack("<IIIIIIIIIIIIIIIIBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", data:sub(25))
    prevSMPTEData = SKupdater(prevSMPTEData , smpteData, megType)
end

function parseHandlercue(data, node, megType)
    -- Error handling
    if data == nil or #data < 436 or #data > 437 then
        gma.echo("Error: Invalid or incomplete data received.")
        return
    end
    local handlercue = {
        dataType = string.byte(data, 24),
        layerID = string.byte(data, 25),
        reserved1 = string.sub(data, 26, 41),
        loopIn = string.unpack("<I4", data, 42),
        loopOut = string.unpack("<I4", data, 46),
        cues = {}
    }

    for i = 1, 18 do
        local cueOffset = 46 + (i - 1) * 24
        local cue = {
            cueType = string.byte(data, cueOffset + 1),
            reserved2 = string.byte(data, cueOffset + 2),
            inTime = string.unpack("<I4", data, cueOffset + 3),
            outTime = string.unpack("<I4", data, cueOffset + 7),
            reserved3 = string.byte(data, cueOffset + 11),
            color = {
                red = string.byte(data, cueOffset + 12),
                green = string.byte(data, cueOffset + 13),
                blue = string.byte(data, cueOffset + 14)
            },
            reserved4 = string.sub(data, cueOffset + 15, cueOffset + 22)
        }
        table.insert(handlercue.cues, cue)
    end

    return handlercue
end

function prevCueHandler(layerCue, node, megType)
    if prevLayersCueData[layerNamesCue[layerCue]] then
        local changes = {}

        for i, cue in ipairs(newCueData.cues) do
            local prevCue = prevLayersCueData[layerNamesCue[layerCue]].cues[i]

            if cue.cueType ~= prevCue.cueType or
                cue.inTime ~= prevCue.inTime or
                cue.outTime ~= prevCue.outTime or
                cue.color.red ~= prevCue.color.red or
                cue.color.green ~= prevCue.color.green or
                cue.color.blue ~= prevCue.color.blue then

                changes[i] = {
                    cueType = cue.cueType ~= prevCue.cueType,
                    inTime = cue.inTime ~= prevCue.inTime,
                    outTime = cue.outTime ~= prevCue.outTime,
                    color = cue.color.red ~= prevCue.color.red or
                    cue.color.green ~= prevCue.color.green or
                    cue.color.blue ~= prevCue.color.blue
                }
            end
        end

        if next(changes) then
            gma.echo("Changes detected in layer " .. layerNamesCue[layerCue] .. ":")
            for i, change in pairs(changes) do
                print("Cue " .. i .. ":")
                if change.cueType then print("  Cue type changed") end
                if change.inTime then print("  In time changed") end
                if change.outTime then print("  Out time changed") end
                if change.color then print("  Color changed") end
            end
        end
    else
        gma.echo("Layer " .. layerNamesCue[layerCue] .. " data stored for the first time")
    end
    prevLayersCueData[layerNamesCue[layerCue]] = newCueData
end


-- Coroutine for sending Opt-IN packages
local function sendOptInCoroutine(udp, header)
    local last_send_time = socket.gettime()
    while true do
        local current_time = socket.gettime()
        if current_time - last_send_time >= 1 then
            sendOptInPackage(udp, header)
            last_send_time = socket.gettime()
        end
        coroutine.yield()
    end
end

local function receiveMessages(udp)
    while true do
        local data = udp:receive()
        if data then
            -- Parse the header from the incoming data
            local header = handleHeader(data)
            -- Check if the nodeType is Master (2)
            if header.nodeType == 2 then
                -- If the first Master node's name has not been set, store this node's name and sequence number
                if firstMasterNodeName == nil then
                    firstMasterNodeName = header.nodeName
                    lastSeq = header.seq
                    gma.echo("Storing the first Master node's name: " .. firstMasterNodeName)
                end 
                -- Check if the node name matches the first Master node's name and if the sequence number is not older
                if header.nodeName == firstMasterNodeName and ((lastSeq < header.seq) or (lastSeq > 200 and header.seq < 50)) then 
                    -- Update the last sequence number
                    lastSeq = header.seq

                    -- Process the incoming message based on the messageType
                    local node = {
                        ip = ip,
                        port = port,
                        header = header
                    }
gma.echo(header.messageType)
                    if header.messageType == 2 then
                        handleOptIn(data, node, "OPT-IN")
                    elseif header.messageType == 3 then
                        handleOptOut(data, node, "OPT-OUT")
                    elseif header.messageType == 5 then
                        handleStatus(data, node, "STATUS")
                    elseif header.messageType == 10 then
                        handleTimeSync(data, node, "SYNC")
                    elseif header.messageType == 13 then
                        handleError(data, node, "NOTIFICATION")
                    elseif header.messageType == 20 then
                        handleRequest(data, node, "REQEST")
                    elseif header.messageType == 101 then
                        handleControl(data, node, "CONTROL")
                    elseif header.messageType == 128 then
                        handleText(data, node, "TEXT")
                    elseif header.messageType == 132 then
                        handleKeyboard(data, node, "KEYBOARD")
                    elseif header.messageType == 254 then
                        handleSMPTETime(data, node, "TIME")
                    elseif header.messageType == 30 then
                        --handleSMPTETime(data, node, "TIME")
gma.cmd("llll")
                    elseif header.messageType == 200 then
                        
                        local datatype = string.unpack("<B", data:sub(25))
                        if datatype == 2 then
                            handleDataMetrics(data, node, "METRICS")
                        elseif datatype == 4 then
                            handleDataMetadata(data, node, "META")
                        elseif datatype == 8 then
                            handleDataMetadata(data, node, "BEATGRID")
                        elseif datatype == 12 then
                            local newCueData = parseHandlercue(data, node, "CUE")
                            layerCue = newCueData.layerID
                            prevCueHandler(layerCue)
                        end
                    end
                    -- Add more elseif cases for other message types...

                else
                    --gma.echo("Ignoring Opt-IN message from non-target Master node or older sequence number")
                end
           else
                --gma.echo("Ignoring Opt-IN message from non-Master") 
            end
        end
    end
  coroutine.yield()
end


local function getIPBcast()
    local network -- Define network variable here
    if ethernetPOrtNum == 0 then
        network = gma.network.getprimaryip() -- Assign value without declaring local
    elseif ethernetPOrtNum == 1 then
        network = gma.network.getsecondaryip() -- Assign value without declaring local
    end
    local num = {}
    local dot = 0
    while true do
        dot = string.find(network, '%.', dot+1)
            if dot == nil then break
            end
        table.insert(num,dot)
    end
    network = string.sub(network, 1, num[3])
    local maip = (network .. '255')
    gma.echo('ShowKontrol TCnet Brodcast IP Address:' .. maip)
    return maip
end

local function main()
    local udp = socket.udp()
    local udp2 = socket.udp()
    local udp3 = socket.udp()
    local udp4 = socket.udp()
    gma.echo("TCnet Startup")
    BROADCAST_IP = getIPBcast()
    nodes = {}
    -- Open a listener on ports
    udp:setoption('reuseaddr', true)
    udp:setoption('reuseport', true)
    udp:setsockname("*", OPTIN_PORT)
    udp:settimeout(0) -- Set the timeout to 0 for non-blocking behavior
    udp2:setoption('reuseaddr', true)
    udp2:setoption('reuseport', true)
    udp2:setsockname("*", TCNet_TIME_PORT)
    udp2:settimeout(0) -- Set the timeout to 0 for non-blocking behavior
    udp3:setoption('reuseaddr', true)
    udp3:setoption('reuseport', true)
    udp3:setsockname("*", NO_DOCS_PORT)
    udp3:settimeout(0) -- Set the timeout to 0 for non-blocking behavior
    udp4:setoption('reuseaddr', true)
    udp4:setoption('reuseport', true)
    udp4:setsockname("*", GMA_PORT)
    udp4:settimeout(0) -- Set the timeout to 0 for non-blocking behavior

    -- Create a TCNet header
    local header = createHeader(10, 3, 5, 2, "GrandMA2", 0, 4, 0, timer())

    -- Create coroutines for sending and receiving Opt-IN messages
    local sendOptInCo = coroutine.create(sendOptInCoroutine)
    local receiveCo = coroutine.create(receiveMessages)
    local receiveCo2 = coroutine.create(receiveMessages)
    local receiveCo3 = coroutine.create(receiveMessages)
    local receiveCo4 = coroutine.create(receiveMessages)

    -- Resume coroutines in a loop
    while true do
        coroutine.resume(sendOptInCo, udp, header)
        coroutine.resume(receiveCo, udp)
        coroutine.resume(receiveCo2, udp2)
        coroutine.resume(receiveCo3, udp3)
        coroutine.resume(receiveCo2, udp4)
    end
end

local function CleanUP()
   udp:close()
   gma.echo("TCnet Shutdown")
end

return main, CleanUP
