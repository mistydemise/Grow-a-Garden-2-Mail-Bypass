local MailLimitBypass = {}
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function GetNetworking()
    local Success, Result = pcall(function()
        return require(ReplicatedStorage.SharedModules.Networking)
    end)
    if Success then return Result end
    return nil
end

local Networking = GetNetworking()
if not Networking then
    return
end

local function GetMailboxController()
    local Success, Result = pcall(function()
        return require(LocalPlayer.PlayerScripts.Controllers.MailboxController)
    end)
    if Success then return Result end
    return nil
end

local MailboxController = GetMailboxController()

function MailLimitBypass.BypassMailLimit()
    local Bypassed = false
    local OriginalSendBatch = nil
    
    pcall(function()
        OriginalSendBatch = Networking.Mailbox.SendBatch
    end)
    
    if not OriginalSendBatch then
        return false
    end
    
    local function HookSendBatch()
        pcall(function()
            local MetaTable = getrawmetatable(game)
            local OldNamecall = MetaTable.__namecall
            
            setreadonly(MetaTable, false)
            MetaTable.__namecall = newcclosure(function(Self, ...)
                local Method = getnamecallmethod()
                if Method == "Fire" and Self == Networking.Mailbox.SendBatch then
                    local Args = {...}
                    if #Args >= 2 then
                        local TargetId = Args[1]
                        local Items = Args[2]
                        local Note = Args[3] or ""
                        
                        if type(Items) == "table" and #Items > 20 then
                            local Batches = {}
                            local MaxBatchSize = 20
                            
                            for Index = 1, #Items, MaxBatchSize do
                                local Batch = {}
                                for J = Index, math.min(Index + MaxBatchSize - 1, #Items) do
                                    table.insert(Batch, Items[J])
                                end
                                table.insert(Batches, Batch)
                            end
                            
                            for _, Batch in ipairs(Batches) do
                                pcall(function()
                                    OriginalSendBatch:Fire(TargetId, Batch, Note)
                                end)
                                task.wait(0.5)
                            end
                            
                            return true
                        end
                    end
                    return OriginalSendBatch(Self, ...)
                end
                if OldNamecall then
                    return OldNamecall(Self, ...)
                end
            end)
            setreadonly(MetaTable, true)
        end)
        return true
    end
    
    local function HookSendBatchRemote()
        pcall(function()
            local Remote = Networking.Mailbox.SendBatch
            if Remote then
                local OldFire = Remote.Fire
                Remote.Fire = function(Self, ...)
                    local Args = {...}
                    if #Args >= 2 then
                        local TargetId = Args[1]
                        local Items = Args[2]
                        local Note = Args[3] or ""
                        
                        if type(Items) == "table" and #Items > 20 then
                            local Batches = {}
                            local MaxBatchSize = 20
                            
                            for Index = 1, #Items, MaxBatchSize do
                                local Batch = {}
                                for J = Index, math.min(Index + MaxBatchSize - 1, #Items) do
                                    table.insert(Batch, Items[J])
                                end
                                table.insert(Batches, Batch)
                            end
                            
                            local Results = {}
                            for _, Batch in ipairs(Batches) do
                                local Success, Result = pcall(function()
                                    return OldFire(Self, TargetId, Batch, Note)
                                end)
                                table.insert(Results, {Success = Success, Result = Result})
                                task.wait(0.5)
                            end
                            
                            return Results
                        end
                    end
                    return OldFire(Self, ...)
                end
            end
        end)
        return true
    end
    
    local function HookSendMail()
        pcall(function()
            local SendMail = Networking.Mailbox.SendMail
            if SendMail then
                local OldFire = SendMail.Fire
                SendMail.Fire = function(Self, ...)
                    local Args = {...}
                    if #Args >= 3 then
                        local TargetId = Args[1]
                        local ItemId = Args[2]
                        local Count = Args[3] or 1
                        local Note = Args[4] or ""
                        
                        if Count > 9999 then
                            local MaxCount = 9999
                            local Remaining = Count
                            local Results = {}
                            
                            while Remaining > 0 do
                                local SendCount = math.min(Remaining, MaxCount)
                                local Success, Result = pcall(function()
                                    return OldFire(Self, TargetId, ItemId, SendCount, Note)
                                end)
                                table.insert(Results, {Success = Success, Result = Result})
                                Remaining = Remaining - SendCount
                                task.wait(0.5)
                            end
                            
                            return Results
                        end
                    end
                    return OldFire(Self, ...)
                end
            end
        end)
        return true
    end
    
    local function HookMailboxController()
        pcall(function()
            if MailboxController then
                local OldSendItem = MailboxController.SendItem
                if OldSendItem then
                    MailboxController.SendItem = function(...)
                        local Args = {...}
                        if #Args >= 3 then
                            local TargetId = Args[1]
                            local ItemData = Args[2]
                            local Count = Args[3] or 1
                            local Note = Args[4] or ""
                            
                            if Count > 9999 then
                                local MaxCount = 9999
                                local Remaining = Count
                                local Results = {}
                                
                                while Remaining > 0 do
                                    local SendCount = math.min(Remaining, MaxCount)
                                    local Success, Result = pcall(function()
                                        return OldSendItem(TargetId, ItemData, SendCount, Note)
                                    end)
                                    table.insert(Results, {Success = Success, Result = Result})
                                    Remaining = Remaining - SendCount
                                    task.wait(0.5)
                                end
                                
                                return Results
                            end
                        end
                        return OldSendItem(...)
                    end
                end
            end
        end)
        return true
    end
    
    local function HookNetworking()
        pcall(function()
            if Networking and Networking.Mailbox then
                local MetaTable = getrawmetatable(Networking.Mailbox)
                if MetaTable then
                    local OldIndex = MetaTable.__index
                    setreadonly(MetaTable, false)
                    MetaTable.__index = newcclosure(function(Table, Key)
                        if Key == "SendBatch" then
                            local Remote = OldIndex(Table, Key)
                            if Remote then
                                local OldFire = Remote.Fire
                                Remote.Fire = function(Self, ...)
                                    local Args = {...}
                                    if #Args >= 2 then
                                        local TargetId = Args[1]
                                        local Items = Args[2]
                                        local Note = Args[3] or ""
                                        
                                        if type(Items) == "table" and #Items > 20 then
                                            local Batches = {}
                                            local MaxBatchSize = 20
                                            
                                            for Index = 1, #Items, MaxBatchSize do
                                                local Batch = {}
                                                for J = Index, math.min(Index + MaxBatchSize - 1, #Items) do
                                                    table.insert(Batch, Items[J])
                                                end
                                                table.insert(Batches, Batch)
                                            end
                                            
                                            local Results = {}
                                            for _, Batch in ipairs(Batches) do
                                                local Success, Result = pcall(function()
                                                    return OldFire(Self, TargetId, Batch, Note)
                                                end)
                                                table.insert(Results, {Success = Success, Result = Result})
                                                task.wait(0.5)
                                            end
                                            
                                            return Results
                                        end
                                    end
                                    return OldFire(Self, ...)
                                end
                                return Remote
                            end
                        end
                        return OldIndex(Table, Key)
                    end)
                    setreadonly(MetaTable, true)
                end
            end
        end)
        return true
    end
    
    local function BypassWithProxy()
        local Success = false
        pcall(function()
            local ProxyMethods = {
                "syn.request",
                "http_request",
                "request",
                "fluxus.request",
                "krnl.request"
            }
            
            for _, Method in ipairs(ProxyMethods) do
                local Function = loadstring("return " .. Method)()
                if Function then
                    local OldFunction = Function
                    _G[Method] = function(...)
                        local Args = {...}
                        if Args[1] and Args[1].Url and Args[1].Url:find("SendBatch") then
                            local Body = Args[1].Body
                            if Body then
                                local Data = HttpService:JSONDecode(Body)
                                if Data and Data.items and #Data.items > 20 then
                                    local Batches = {}
                                    local MaxBatchSize = 20
                                    
                                    for Index = 1, #Data.items, MaxBatchSize do
                                        local Batch = {}
                                        for J = Index, math.min(Index + MaxBatchSize - 1, #Data.items) do
                                            table.insert(Batch, Data.items[J])
                                        end
                                        table.insert(Batches, Batch)
                                    end
                                    
                                    local Results = {}
                                    for _, Batch in ipairs(Batches) do
                                        local NewData = table.clone(Data)
                                        NewData.items = Batch
                                        local NewBody = HttpService:JSONEncode(NewData)
                                        Args[1].Body = NewBody
                                        local Result = OldFunction(unpack(Args))
                                        table.insert(Results, Result)
                                        task.wait(0.5)
                                    end
                                    
                                    return Results
                                end
                            end
                        end
                        return OldFunction(...)
                    end
                    Success = true
                    break
                end
            end
        end)
        return Success
    end
    
    local BypassMethods = {
        HookSendBatch,
        HookSendBatchRemote,
        HookSendMail,
        HookMailboxController,
        HookNetworking,
        BypassWithProxy
    }
    
    for _, Method in ipairs(BypassMethods) do
        local Success = pcall(Method)
        if Success then
            Bypassed = true
        end
    end
    
    return Bypassed
end

function MailLimitBypass.SendBypassed(TargetId, Items, Note)
    if type(Items) ~= "table" then
        return false
    end
    
    if #Items == 0 then
        return false
    end
    
    local MaxBatchSize = 20
    local Batches = {}
    
    for Index = 1, #Items, MaxBatchSize do
        local Batch = {}
        for J = Index, math.min(Index + MaxBatchSize - 1, #Items) do
            table.insert(Batch, Items[J])
        end
        table.insert(Batches, Batch)
    end
    
    local Results = {}
    local TotalSent = 0
    
    for _, Batch in ipairs(Batches) do
        local Success, Result = pcall(function()
            return Networking.Mailbox.SendBatch:Fire(TargetId, Batch, Note or "")
        end)
        
        table.insert(Results, {Success = Success, Result = Result})
        if Success then
            TotalSent = TotalSent + #Batch
        end
        
        task.wait(0.5)
    end
    
    return {
        Success = true,
        TotalSent = TotalSent,
        TotalBatches = #Batches,
        Results = Results
    }
end

function MailLimitBypass.SendBypassedWithDelay(TargetId, Items, Note, Delay)
    Delay = Delay or 1.0
    
    if type(Items) ~= "table" then
        return false
    end
    
    if #Items == 0 then
        return false
    end
    
    local MaxBatchSize = 20
    local Batches = {}
    
    for Index = 1, #Items, MaxBatchSize do
        local Batch = {}
        for J = Index, math.min(Index + MaxBatchSize - 1, #Items) do
            table.insert(Batch, Items[J])
        end
        table.insert(Batches, Batch)
    end
    
    local Results = {}
    local TotalSent = 0
    
    for Index, Batch in ipairs(Batches) do
        local Success, Result = pcall(function()
            return Networking.Mailbox.SendBatch:Fire(TargetId, Batch, Note or "")
        end)
        
        table.insert(Results, {Success = Success, Result = Result})
        if Success then
            TotalSent = TotalSent + #Batch
        end
        
        if Index < #Batches then
            task.wait(Delay)
        end
    end
    
    return {
        Success = true,
        TotalSent = TotalSent,
        TotalBatches = #Batches,
        Results = Results
    }
end

function MailLimitBypass.SendStackableBypassed(TargetId, ItemId, Count, Note)
    if type(Count) ~= "number" or Count <= 0 then
        return false
    end
    
    local MaxCount = 9999
    local Results = {}
    local TotalSent = 0
    local Remaining = Count
    
    while Remaining > 0 do
        local SendCount = math.min(Remaining, MaxCount)
        local Success, Result = pcall(function()
            return Networking.Mailbox.SendMail:Fire(TargetId, ItemId, SendCount, Note or "")
        end)
        
        table.insert(Results, {Success = Success, Result = Result})
        if Success then
            TotalSent = TotalSent + SendCount
        end
        
        Remaining = Remaining - SendCount
        if Remaining > 0 then
            task.wait(0.5)
        end
    end
    
    return {
        Success = true,
        TotalSent = TotalSent,
        Results = Results
    }
end

function MailLimitBypass.BypassDailyLimit()
    pcall(function()
        local DailyLimit = 500
        local SentToday = 0
        
        local function CheckDailyLimit()
            if SentToday >= DailyLimit then
                return false
            end
            return true
        end
        
        local OldSendBatch = Networking.Mailbox.SendBatch.Fire
        Networking.Mailbox.SendBatch.Fire = function(Self, ...)
            if not CheckDailyLimit() then
                return false
            end
            
            local Args = {...}
            local Result = OldSendBatch(Self, ...)
            
            if #Args >= 2 then
                local Items = Args[2]
                if type(Items) == "table" then
                    SentToday = SentToday + #Items
                end
            end
            
            return Result
        end
        
        return true
    end)
    return false
end

function MailLimitBypass.ResetDailyCounter()
    SentToday = 0
    return true
end

return MailLimitBypass
