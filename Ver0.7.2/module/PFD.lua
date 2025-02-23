do
    -- Author: <Authorname> (Please change this in user settings, Ctrl+Comma)
    -- GitHub: <GithubLink>
    -- Workshop: <WorkshopLink>
    --
    --- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
    --- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


    --[====[ HOTKEYS ]====]
    -- Press F6 to simulate this file
    -- Press F7 to build the project, copy the output from /_build/out/ into the game to use
    -- Remember to set your Author name etc. in the settings: CTRL+COMMA


    --[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
    ---@section __LB_SIMULATOR_ONLY__
    do
        ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
        simulator = simulator
        simulator:setScreen(1, "1x1")
        simulator:setScreen(2, "1x1")
        simulator:setProperty("F1",
            "0000044404AA000AEAEA4E4E4A248A26E624800048884844480A4A004E400004800E000000422488EAAAEC444EE2E8EE2E2EAAE22E8E2EE8EAEE2244EAEAE")
        simulator:setProperty("F2",
            "EAE2E0404004048248420E0E084248E26048CEC8EAEAAEACAEE888ECAAADE8C8EE8C88E8BBEBBEBBE444EE444CBBCBB8888EEEEBBBEEEBEAAAEEBE88EBBC6")
        simulator:setProperty("F3",
            "EAECBE8E2EE4444AAAAEAAAA4AAEEAAA4AAAAE44E248EC888C88422622264A0000000E84000006AE88EAE00E8E22EAE00ECE64E446AE2E88EAA404444044C")
        simulator:setProperty("F4",
            "88ACA44446008EE00E6600EAE0EAE80EAE2006880EC6E04E4400AAE00AA400AEE00A4A0AA480E6CE6484644444C424CEEEEE")
        simulator:setProperty("indicatorColor", "200,100,100,100,200,100,100,100,200,255,255,255")
        simulator:setProperty("SkyColor", "2020FF")
        simulator:setProperty("LandColor", "20FF20")
        simulator:setProperty("CenterLineColor", "FFFFFF")
        simulator:setProperty("Altitude Unit", "1")
        simulator:setProperty("Speed Unit", 3.6)


        -- Runs every tick just before onTick; allows you to simulate the inputs changing
        ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
        ---@param ticks     number Number of ticks since simulator started
        function onLBSimulatorTick(simulator, ticks)
            simulator:setInputNumber(4, simulator:getSlider(4) * math.pi / 2) --* 2 - math.pi)
            simulator:setInputNumber(5, simulator:getSlider(5) * math.pi/2 ) --* 2 - math.pi)
            simulator:setInputNumber(6, simulator:getSlider(6) * math.pi) --* 2 - math.pi)
        end

        ;
    end
    ---@endsection


    --[====[ IN-GAME CODE ]====]

    -- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
    -- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!


    -- Tick function that will be executed every logic tick
end



---------[====[ 定義部 ]====]----------
Phys = {}
oldalt=0


--コンバータ--
function convert()
    -- This uses the game's basis. That is,
    --     vehicle   world   color
    -- x   right     east    red
    -- y   up        up      green
    -- z   forward   north   blue

    -- Get angles.
    Phys.x   = input.getNumber(1)
    Phys.alt = input.getNumber(2)
    Phys.y   = input.getNumber(3)
    Phys.VS  = Phys.alt-oldalt
    oldalt=Phys.alt

    local phyX = input.getNumber(4)
    local phyY = input.getNumber(5)
    local phyZ = input.getNumber(6)

    -- Get global angular velocities.
    local phyAngX = input.getNumber(10)
    local phyAngY = input.getNumber(11)
    local phyAngZ = input.getNumber(12)

    Phys.speed = input.getNumber(13)

    -- sin, 'cos I like it.
    local cx, sx = math.cos(phyX), math.sin(phyX)
    local cy, sy = math.cos(phyY), math.sin(phyY)
    local cz, sz = math.cos(phyZ), math.sin(phyZ)

    -- Build matrix.
    local matrix00 = cy * cz
    local matrix01 = -cx * sz + sx * sy * cz
    local matrix02 = sx * sz + cx * sy * cz
    local matrix10 = cy * sz
    local matrix11 = cx * cz + sx * sy * sz
    local matrix12 = -sx * cz + cx * sy * sz
    local matrix20 = -sy
    local matrix21 = sx * cy
    local matrix22 = cx * cy


    -- Equally good alternative if you prefer.
    Phys.tilt_x = math.atan(matrix10, math.sqrt(matrix12 * matrix12 + matrix11 * matrix11)) -- / (math.pi * 2)
    Phys.tilt_y = math.atan(matrix11, math.sqrt(matrix10 * matrix10 + matrix12 * matrix12)) -- / (math.pi * 2)
    Phys.tilt_z = math.atan(matrix12, math.sqrt(matrix11 * matrix11 + matrix10 * matrix10)) -- / (math.pi * 2)

    -- Compute compasses.
    local compassSensor = -math.atan(math.sin(phyX) * math.sin(phyZ) + math.cos(phyX) * math.sin(phyY) * math.cos(phyZ),
        math.cos(phyX) * math.cos(phyY)) / 2 / math.pi
    Phys.compass = ((((1 - compassSensor) % 1) * (math.pi * 2))) or 0


    -- Transform them to the local frame.
    Phys.angular_x = matrix00 * phyAngX + matrix10 * phyAngY + matrix20 * phyAngZ
    Phys.angular_y = matrix01 * phyAngX + matrix11 * phyAngY + matrix21 * phyAngZ
    Phys.angular_z = matrix02 * phyAngX + matrix12 * phyAngY + matrix22 * phyAngZ


    Phys.roll  = math.atan(-Phys.tilt_y, Phys.tilt_x)
    Phys.pitch = -Phys.tilt_z --* (math.pi * 2)
end

do -------------------------------------[====[ 処理系 ]====]----------------------------------------
    function split(str, delim)
        if string.find(str, delim) == nil then
            return { str }
        end

        local result = {}
        local pat = "(.-)" .. delim .. "()"
        local lastPos
        for part, pos in string.gmatch(str, pat) do
            table.insert(result, part)
            lastPos = pos
        end
        table.insert(result, string.sub(str, lastPos))
        return result
    end

    function Colorconv16(name)                                         --16進数のカラーコードをRGBに変換する
        local Color = tonumber(property.getText(name), 16) or 0
        return (Color >> 16) & 0xff, (Color >> 8) & 0xff, Color & 0xff --R,G,B
    end

    function lerp(MIN, MAX, X) --  0~1  f(x)と同じ挙動
        return (1 - X) * MIN + X * MAX
    end
    function sign(x)
        if x<0 then
          return -1
        elseif x>=0 then
          return 1
        else
          return 0
        end
    end
    -------------------------------------------処理系終わり--------------------------------------------
end



do -------------------------------------[====[ 描画系 ]====]----------------------------------------
    ----------------------FONT----------------------
    function drawNewFont(NewFontX, NewFontY, NewFontZ)
        if type(NewFontZ) == "number" then
            NewFontZ = tostring(NewFontZ)
        end
        NewFontD = property.getText("F1") .. property.getText("F2") .. property.getText("F3") .. property.getText("F4")
        for i = 1, NewFontZ:len() do
            NewFontC = NewFontZ:sub(i, i):byte() * 5 - 159
            for j = 1, 5 do
                NewFontF = "0x" .. NewFontD:sub(NewFontC, NewFontC + 4):sub(j, j)
                for k = 1, 3 do
                    if NewFontF & 2 ^ (4 - k) > 0 then
                        NewFontP = NewFontX + i * 4 + k - 5
                        NewFontQ = NewFontY + j - 1
                        screen.drawLine(NewFontP, NewFontQ, NewFontP + 1, NewFontQ)
                    end
                end
            end
        end
    end

    function horizon() --水平儀
        local XPos = 0
        local YPos = 0
        local w = 32
        local h = 32

        local lineangle = 10    --何度ごとに線を描画するかの指定
        local minlinelength = 5 --↑の線の幅を指定
        local maxlinelength = 9

        maxlinelength = maxlinelength - minlinelength
        for i = -90 // lineangle, 90 // lineangle do                                                                --lineangleに合わせた線を引くためのfor文
            local offsetX = math.cos(Phys.roll) * (math.deg(Phys.pitch)) + w / 2                                      --┬─ピッチ方向に線を動かすためのやつ
            local offsetY = math.sin(Phys.roll) * (math.deg(Phys.pitch)) + h / 2                                      --┘

            local X, Y = math.cos(Phys.roll) * i * lineangle + offsetX,
                math.sin(Phys.roll) * i * lineangle + offsetY                                                         --画面中心からロール角分傾けた線を描画したい線の半径まで引く
            local line1 = Phys.roll +
            math.pi /
            2                                                                                                         --┬─↑でひいた線の先端に垂直な線の角度　左右分。
            local line2 = -Phys.roll + math.pi / 2                                                                    --┘

            local linelength = math.cos(lerp(0, math.pi / 2, Phys.pitch + math.rad(i))) * maxlinelength +
            minlinelength                                                                                             --端に行くほど線が短くなる

            if i == 0 then                                                                                            --水平線の色
                screen.setColor(255, 0, 255)
                linelength = 20
            elseif i > 0 then --地面の色
                screen.setColor(50, 255, 50)
            else              --空の色
                screen.setColor(50, 50, 255)
            end

            local pixelX_1, pixelY_1 = math.cos(line1) * linelength + X, math.sin(line1) * linelength + Y  --┬─描画する線の座標計算
            local pixelX_2, pixelY_2 = math.cos(line2) * linelength + X, -math.sin(line2) * linelength + Y --┘

            screen.drawLine(pixelX_1 + XPos, pixelY_1 + YPos - 1, pixelX_2 + XPos, pixelY_2 + YPos - 1)    --線を描画する
            screen.drawText(pixelX_2 + XPos -1 - 3*sign(-Phys.roll), pixelY_2 + YPos - 3, string.format("%-1d", math.abs(i // 1)))
        end
        --screen.setColor(255,255,255)
        --screen.drawText(0,25,tostring(Phys.pitch))
    end

    function compassBar(ta)            --targetangle = degrees
        local temp = 0
        --local targetangle = math.rad(targetangle)
        local NESWdetadeg={0,math.pi*0.5,math.pi,math.pi*1.5}
        local NESWdetacharacter={"N","E","S","W"}

        screen.setColor(5, 70, 5)--↓らは線の上にNESWを表示する
        for i=1,4,1 do
            temp = (math.deg(-Phys.compass+NESWdetadeg[i]+math.pi)%360-180)*0.6+15
            screen.drawText(temp - 1, 24,NESWdetacharacter[i])
        end
        --[[
        screen.setColor(5, 70, 5)--↓らは線の上にNESWを表示する
        temp = (math.deg(-Phys.compass)*0.6+15)
        screen.drawText(temp - 1, 24, "N")
        temp = ((math.deg(-Phys.compass)+90)*0.6+15)
        screen.drawText(temp - 1, 24, "E")
        temp = ((math.deg(-Phys.compass)+180)*0.6+15)
        screen.drawText(temp - 1, 24, "S")
        temp = ((math.deg(-Phys.compass)+270)*0.6+15)
        screen.drawText(temp - 1, 24, "W")


        temp = (math.deg(-Phys.compass)*0.6+15)
        screen.drawText(temp - 1, 24, "N")
        temp = ((math.deg(-Phys.compass)-90)*0.6+15)
        screen.drawText(temp - 1, 24, "E")
        temp = ((math.deg(-Phys.compass)-180)*0.6+15)
        screen.drawText(temp - 1, 24, "S")
        temp = ((math.deg(-Phys.compass)-270)*0.6+15)
        screen.drawText(temp - 1, 24, "W")


]]

        screen.setColor(3, 2, 2)
        screen.drawRectF(0, 29, 32, 3)
        screen.drawRectF(10, 23, 11, 7) --現在方位表示の背景
        screen.drawRectF(9, 24, 13, 5)

        screen.setColor(255, 255, 225)
        drawNewFont(10, 24, string.format("%03d", tonumber(math.floor(math.deg(Phys.compass))))) --現在方位を三桁表示

        screen.setColor(5, 70, 5)
        --[[
        for i = 0, 32 / linespace,1 do --方位線の描画
            local temp = (-Phys.compass * (linedeg / linespace) + i * linespace) % 32
            screen.drawLine(temp, 29 + i % 2, temp, 33)
        end]]
--[[
        for i = -72, 72, 1 do
            if math.abs(i)%18==0 then
                screen.setColor(50, 70, 5)
            else
                screen.setColor(5, 70, 5)
            end
            local temp =((-Phys.compass-math.rad(i*5)) * 31)//1 + 15
            screen.drawLine(temp, 29+ i % 2, temp, 33)
        end
]]
        for i=-72,72,1 do
            if math.abs(i)%18==0 then
                screen.setColor(50, 70, 50)
            else
                screen.setColor(5, 70, 5)
            end
            local temp = (3*i+15) -(math.deg(Phys.compass+math.pi)%360-180)*0.6
            screen.drawLine(temp, 29 + i % 2, temp, 33)
            
        end
        screen.setColor(250, 40, 40) --目標の角度
        local temp = -(math.deg(-ta+Phys.compass+math.pi)%360-180)*0.6 + 15
        screen.drawLine(temp, 29, temp, 33)

    end

    function Indicator(boolA, boolB, boolC, boolD) --四角4つ
        colorTable = split(indicatorColor, ",")
        if boolA then
            screen.setColor(tonumber(colorTable[1]), tonumber(colorTable[2]), tonumber(colorTable[3]))
        else
            screen.setColor(30, 30, 30)
        end
        screen.drawRectF(0, 4, 4, 3) --

        if boolB then
            screen.setColor(tonumber(colorTable[4]), tonumber(colorTable[5]), tonumber(colorTable[6]))
        else
            screen.setColor(30, 30, 30)
        end
        screen.drawRectF(0, 10, 4, 3) --



        if boolC then
            screen.setColor(tonumber(colorTable[7]), tonumber(colorTable[8]), tonumber(colorTable[9]))
        else
            screen.setColor(30, 30, 30)
        end
        screen.drawRectF(0, 16, 4, 3) --




        if boolD then
            screen.setColor(tonumber(colorTable[10]), tonumber(colorTable[11]), tonumber(colorTable[12]))
        else
            screen.setColor(30, 30, 30)
        end
        screen.drawRectF(0, 22, 4, 3) --
    end

    function altimeter()
        screen.setColor(0, 0, 0, 70) --背景
        screen.drawRectF(0, 12, 32, 7)

        screen.setColor(255, 255, 255)
        screen.drawLine(2, 0, 2, 32)

        screen.setColor(255, 190, 0) --左の四角
        screen.drawRectF(0, 13, 4, 5)
        screen.drawLine(4, 14, 4, 17)
        screen.drawLine(5, 15, 8, 15)

        --screen.drawTriangleF(30, 16, 32, 13, 32, 19) --右の三角
        screen.setColor(200,10,10)
        screen.drawRectF(0,15,2,-Phys.VS*40)
        

        screen.setColor(255, 255, 255) --高度の数字
        screen.drawTextBox(6, 0, 26, 32, string.format("%04d", math.floor(Phys.alt * altunit)), 0, 0)
    end

    function speedmeter()
        screen.setColor(2, 2, 2)
        screen.drawRectF(11, 12, 18, 7)

        screen.setColor(255, 255, 255)
        screen.drawLine(29, 0, 29, 20)

        screen.setColor(255, 180, 0)
        screen.drawLine(27, 15, 27, 16)
        screen.drawLine(28, 14, 28, 17)
        screen.drawLine(29, 13, 29, 18)
        screen.drawLine(30, 13, 30, 18)

        screen.setColor(255, 255, 255)
        screen.drawText(12, 13, string.format("%03d", math.floor(Phys.speed * spdunit)))
    end

    --------------------------------------------描画系終わり-------------------------------------------
end



do -------------------------------------[====[ 実行部 ]====]----------------------------------------
    SkyColorR, SkyColorG, SkyColorB = Colorconv16("SkyColor")
    LandColorR, SkyColorG, SkyColorB = Colorconv16("LandColor")
    SkyColorR, SkyColorG, SkyColorB = Colorconv16("CenterLineColor")

    indicatorColor = property.getText("indicatorColor")
    --indicatorColor = "200,100,100,100,200,100,100,100,200,255,255,255"

    altunit = property.getNumber("Altitude Unit")
    spdunit = property.getNumber("Speed Unit")



    indicatorbool = { false, false, false, false }

    monitorSwap = property.getBool("Monitor Swap")
    monitorID = false

    targetAngle = 0

    function onTick() ----------------------[====[ onTick ]====]----------------------------------------



        targetAngle = input.getNumber(21)

        convert()
        indicatorbool = {
            input.getBool(1),
            input.getBool(2),
            input.getBool(3),
            input.getBool(4)
        }


        monitorID = false
    end               -----------------------------------------onTick終わり-------------------------------------------

    function onDraw() ----------------------[====[ onDraw ]====]----------------------------------------
        screen.setColor(10, 10, 10)
        screen.drawClear()

        if monitorID ~= monitorSwap then --[====[ 左のモニター用の描画 ]====]
            --

            w, h = 32, 32 --画面の縦横を取得

            compassBar(targetAngle)
            speedmeter()

            Indicator(indicatorbool[1], indicatorbool[2], indicatorbool[3], indicatorbool[4])

            monitorID = true
        else --[====[ 右のモニター用の描画 ]====]
            --

            horizon()
            altimeter()
            monitorID = true
        end
    end -----------------------------------------onDraw終わり-------------------------------------------

    --------------------------------------------実行部終わり-------------------------------------------
end



--テンプレ--
---------------------------------------[====[        ]====]----------------------------------------
------------------------------------------        終わり-------------------------------------------
