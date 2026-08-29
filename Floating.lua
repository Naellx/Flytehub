-- [[ FLOATING ICON MODULE (SECURED) & URL SUPPORT ]] --
return function(Window, CustomIconUrl)
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local LocalPlayer = Players.LocalPlayer
    
    -- [ðŸ›¡ï¸ SECURE FOLDER ANTI-CHEAT BYPASS ðŸ›¡ï¸]
    -- Kita gunakan gethui() agar tidak terdeteksi oleh BAC-3269 di PlayerGui
    local SecureUIFolder = (gethui and gethui()) or CoreGui

    -- [ðŸŽ¨ CONFIGURATION]
    -- Masukkan URL Gambar (https://...) atau rbxassetid:// di bawah ini.
    -- Jika kamu mengirim URL dari script pemanggil: result(Window, "https://link.com/gambar.png") maka prioritas CustomIconUrl.
    local TargetIconURL = CustomIconUrl or "https://raw.githubusercontent.com/Naellx/Flytehub/refs/heads/main/044af82337793fc1493d881ca7be1fc6.webp" 

    -- Variables
    local uisConnection = nil
    local rgbConnection = nil 
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    -- [[ HELPER: CONVERT URL TO CUSTOM ASSET ]]
    local function GetIcon(url)
        local defaultIcon = "rbxassetid://140026247905567"
        if not url or url == "" then return defaultIcon end
        
        -- Jika formatnya sudah bawaan Roblox
        if url:match("^rbxassetid://") or url:match("^rbxthumb://") then
            return url
        end
        
        -- Jika URL berupa link eksternal (http/https)
        if url:match("^http") then
            local getasset = getcustomasset or getsynasset
            if getasset and isfile and writefile then
                -- Buat nama unik dari URL sebagai Cache agar tidak perlu download berulang kali
                local safeHash = url:gsub("[^%w]", ""):sub(-20) 
                local fileName = "SysHub_IconCache_" .. safeHash .. ".png"
                
                -- Jika file belum ada di workspace executor, download!
                if not isfile(fileName) then
                    local success, imgData = pcall(function() return game:HttpGet(url) end)
                    if success and imgData then
                        writefile(fileName, imgData)
                    else
                        warn("[SysHub] Gagal mendownload icon dari URL.")
                        return defaultIcon
                    end
                end
                
                -- Load gambar dari file lokal
                return getasset(fileName)
            else
                warn("[flyteHub] Executor kamu tidak mensupport 'getcustomasset'. Menggunakan icon default.")
                return defaultIcon
            end
        end
        
        return defaultIcon
    end

    -- 1. Create UI
    local function CreateFloatingIcon()
        -- Hapus UI lama jika ada di Secure Folder
        local existingGui = SecureUIFolder:FindFirstChild("CustomFloatingIcon_RockHub")
        if existingGui then existingGui:Destroy() end

        local FloatingIconGui = Instance.new("ScreenGui")
        FloatingIconGui.Name = "CustomFloatingIcon_RockHub"
        FloatingIconGui.DisplayOrder = 999
        FloatingIconGui.ResetOnSpawn = false 
        
        -- [ðŸ›¡ï¸ BYPASS] Set parent ke Secure Folder, BUKAN ke PlayerGui
        FloatingIconGui.Parent = SecureUIFolder

        local FloatingFrame = Instance.new("Frame")
        FloatingFrame.Name = "FloatingFrame"
        FloatingFrame.Position = UDim2.new(0, 50, 0.4, 0) 
        FloatingFrame.Size = UDim2.fromOffset(45, 45) 
        FloatingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        FloatingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        FloatingFrame.BackgroundTransparency = 0
        FloatingFrame.BorderSizePixel = 0
        FloatingFrame.Parent = FloatingIconGui

        local FrameStroke = Instance.new("UIStroke")
        FrameStroke.Color = Color3.fromHex("FF0F7B") 
        FrameStroke.Thickness = 2
        FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        FrameStroke.Parent = FloatingFrame

        Instance.new("UICorner", FloatingFrame).CornerRadius = UDim.new(0, 12)

        local IconImage = Instance.new("ImageLabel")
        IconImage.Name = "Icon"
        
        -- ðŸ”¥ [NEW] Menggunakan fungsi helper untuk me-load URL / Asset ID
        IconImage.Image = GetIcon(TargetIconURL) 
        
        IconImage.BackgroundTransparency = 1
        IconImage.Size = UDim2.new(1, -4, 1, -4) 
        IconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
        IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
        IconImage.Parent = FloatingFrame
        
        Instance.new("UICorner", IconImage).CornerRadius = UDim.new(0, 10)
        
        -- Return FrameStroke juga supaya bisa dianimasikan
        return FloatingIconGui, FloatingFrame, FrameStroke
    end

    -- 2. Setup Logic (Drag, Click, & RGB Animation)
    local function SetupFloatingIcon(FloatingIconGui, FloatingFrame, FrameStroke)
        if uisConnection then uisConnection:Disconnect() uisConnection = nil end
        if rgbConnection then rgbConnection:Disconnect() rgbConnection = nil end

        -- RGB Rainbow Loop
        rgbConnection = RunService.RenderStepped:Connect(function()
            if FrameStroke and FrameStroke.Parent then
                FrameStroke.Color = Color3.fromHSV(tick() % 3 / 3, 1, 1)
            else
                rgbConnection:Disconnect()
                rgbConnection = nil
            end
        end)

        local function update(input)
            local delta = input.Position - dragStart
            FloatingFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X, 
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end

        FloatingFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = FloatingFrame.Position
                
                local didMove = false
                local connection, moveConnection

                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        connection:Disconnect()
                        if moveConnection then moveConnection:Disconnect() end

                        if not didMove then
                            -- TOGGLE WINDOW FUNCTION
                            if Window and Window.Toggle then
                                Window:Toggle()
                            end
                        end
                    end
                end)

                moveConnection = input.Changed:Connect(function()
                     if dragging and (input.Position - dragStart).Magnitude > 5 then
                         didMove = true
                         moveConnection:Disconnect()
                     end
                end)
            end
        end)

        FloatingFrame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        uisConnection = UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then update(input) end
        end)

        -- Connect to Window Events (Hide icon when menu is open)
        if Window then
            Window:OnOpen(function() FloatingIconGui.Enabled = false end)
            Window:OnClose(function() FloatingIconGui.Enabled = true end)
        end
    end

    -- 3. Initialization
    local function InitializeIcon()
        if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
        local gui, frame, stroke = CreateFloatingIcon()
        if gui and frame and stroke then SetupFloatingIcon(gui, frame, stroke) end
    end

    -- 4. Respawn Handler
    local respawnConn
    if _G.RockHubIconRespawn then _G.RockHubIconRespawn:Disconnect() end
    
    respawnConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        InitializeIcon()
    end)
    _G.RockHubIconRespawn = respawnConn

    -- Start immediately
    InitializeIcon()
end
