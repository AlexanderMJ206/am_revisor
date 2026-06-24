Bridge = Bridge or {}

function Bridge.DebugPrint(msg)
    print(('[am_revisor] %s'):format(msg))
end

function Bridge.ResourceStarted(name)
    return GetResourceState(name) == 'started'
end
