local mb = require('moonbot_core')

-- Handlers to reduce your work <3
-- If you're not using MoonLoader, make sure to call mb.updateCallbacks and mb.unload()
addEventHandler('onD3DPresent', mb.updateCallbacks)
addEventHandler('onScriptTerminate', function(script, quit)
    if script == thisScript() then
        mb.unload()
    end
end)

function getCurrentServerDetails()
    -- Change to your code if you're not using MoonLoader
    return sampGetCurrentServerAddress()
end

return mb