-- viewer.lua - CC屏幕查看器
-- 在CC电脑上显示现实电脑的屏幕

-- 检查必要的库
if not json then
    print("error:json")
    print("CC: Tweaked")
    return
end

if not ws then
    print("error:websocket")
    print("CC: Tweaked")
    return
end

print("========== CC viewer ==========")
print("q for quit")
print("r for restart")
print("=================================")
print()

local defaultServer = "ws://192.168.1.100:8080"
local serverUrl = defaultServer

term.write("输入服务器地址 (默认: " .. defaultServer .. "): ")
local input = read()

if input and input ~= "" then
    serverUrl = input
end

print("connect: " .. serverUrl)

local connected = false
local client = nil
local frameCount = 0

local width, height = term.getSize()
print("screen size: " .. width .. "x" .. height)

local function connect()
    print("connecting...")
    
    local success, conn = pcall(function()
        return ws.connect(serverUrl)
    end)
    
    if success and conn then
        client = conn
        connected = true
        print("successed")
        return true
    else
        print("failed")
        if conn then
            print("error: " .. tostring(conn))
        end
        return false
    end
end

local function disconnect()
    if client then
        pcall(function()
            client.close()
        end)
        client = nil
    end
    connected = false
    print("end")
end

local function displayFrame(data)
    if not data or not data.data then
        return
    end
    
    term.clear()
    
    for _, pixel in ipairs(data.data) do
        local x = pixel.x
        local y = pixel.y
        
        if x >= 1 and x <= width and y >= 1 and y <= height then
            term.setCursorPos(x, y)
            
            if pixel.f then
                term.setTextColor(pixel.f)
            else
                term.setTextColor(colors.white)
            end
            
            if pixel.b then
                term.setBackgroundColor(pixel.b)
            else
                term.setBackgroundColor(colors.black)
            end
            
            term.write(pixel.c or " ")
        end
    end
    
    term.setCursorPos(1, height)
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.clearLine()
    
    local status = string.format("fps: %d | q quit | r restart, frameCount)
    term.write(status)
    
    frameCount = frameCount + 1
end

print("starting...")
print("waiting...")

if not connect() then
    print("can't connect")
    print("press any key to quit")
    os.pullEvent("key")
    return
end

local running = true

while running do
    if connected and client then
        local success, message = pcall(function()
            return client.receive(0)
        end)
        
        if success and message then
            local data = json.decode(message)
            
            if data then
                if data.type == "welcome" then
                    print("server: " .. (data.message or ""))
                elseif data.type == "screen_frame" then
                    displayFrame(data)
                end
            end
        end
    end
    
    local event = os.pullEventRaw()
    
    if event == "key" then
        local key = os.pullEvent()
        
        if key == keys.q then
            running = false
            print("quiting...")
        elseif key == keys.r then
            print("restarting...")
            disconnect()
            connect()
        end
    end
    
    sleep(0.05)
end

disconnect()
term.clear()
term.setCursorPos(1, 1)
print("exited")
print("allframes: " .. frameCount)