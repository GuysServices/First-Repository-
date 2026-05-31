-- This is the tiny script you give to your users/customers!

-- Show a nice console message
print("[Ketamine Hub] Initializing Auth...")
warn("[Ketamine Hub] Connecting to secure server...")

-- Wait just a tiny bit so it looks like it's doing complex backend work
task.wait(1.5)

-- Fetch the actual obfuscated CustomLoader.lua directly from your Python Auth Server!
-- NOTE: When you put your server online, change "127.0.0.1:5000" to your server's domain/IP.
local success, loaderCode = pcall(function()
    return game:HttpGet("http://127.0.0.1:5000/loader")
end)

if success and loaderCode and loaderCode ~= "" then
    print("[Ketamine Hub] Auth Initialized! Loading UI...")
    
    -- Execute the loader which shows the Key Input UI
    local func, err = loadstring(loaderCode)
    if func then
        func()
    else
        warn("[Ketamine Hub] Error parsing loader: ", err)
    end
else
    warn("[Ketamine Hub] Failed to connect to Auth Server. It might be offline.")
end
