require "/objects/isn_sharedobjectscripts.lua"

function isn_getCurrentPowerInput()
	if type(storage.powerInNode)~="number" then
		return 0
	end

	local totalInput = 0
	local connectedDevices
	local output = 0
	local isBattery = isn_isBattery()
	connectedDevices = isn_getAllDevicesConnectedOnNode(storage.powerInNode,"input")
	for key, value in pairs (connectedDevices) do
		output = world.callScriptedEntity(value,"isn_getCurrentPowerOutput")
		if output ~= nil then totalInput = totalInput + output end
	end
	return totalInput
end

function isn_hasRequiredPower()
	local power = isn_getCurrentPowerInput()
	local requirement = config.getParameter("isn_requiredPower")
	if power == nil then return false end
	if requirement == nil then return true end
	
	if power >= requirement then return true
	else return false end
end

function isn_requiredPowerValue()
	local req

	if config.getParameter("isn_powerPassthrough") then
		req = isn_sumOutboundPowerReq()
	else
		req = config.getParameter("isn_requiredPower")
	end
	if req == nil then return nil end

	return req
end

function isn_canSupplyPower()
	if config.getParameter("isn_powerSupplier") then return true end
	return false
end

function isn_canRecievePower()
	if config.getParameter("isn_powerReciever") then return true end
	return false
end

function isn_doesNotConsumePower()
	if config.getParameter("isn_freePower") then return true end
	return false
end

function isn_isPowerPassthrough()
	if config.getParameter("isn_powerPassthrough") then return true end
	return false
end

function isn_isBattery()
	local capacity = config.getParameter("isn_batteryCapacity")
	if capacity ~= nil and capacity > 0 then return true end
	return false
end

function isn_areActivePowerDevicesConnectedOnOutboundNode()
	if not storage.powerOutNode then return false end
	local devicelist = isn_getAllDevicesConnectedOnNode(storage.powerOutNode,"output")
	if devicelist == nil then return false end
	for _, value in pairs(devicelist) do
		if world.callScriptedEntity(value,"isn_canRecievePower") then
			--if not world.callScriptedEntity(value,"isn_doesNotConsumePower") then
				if world.callScriptedEntity(value,"isn_activeConsumption") then
					return true
				end
			--end
		end
	end
	return false
end

function isn_activeConsumption()
	if config.getParameter("isn_powerPassthrough") then -- It's a conduit (or similar device), better check what downstream says -r
		if isn_areActivePowerDevicesConnectedOnOutboundNode(storage.powerInNode) then
			return true
		end
	elseif storage.activeConsumption == nil then
		return false
	end
	return storage.activeConsumption
end

function isn_checkValidOutput()
	local connectedDevices = isn_getAllDevicesConnectedOnNode(storage.powerOutNode,"output")
	if connectedDevices == nil then return false end
	for _, value in pairs(connectedDevices) do
		if world.callScriptedEntity(value,"isn_canRecievePower") then
			if not world.callScriptedEntity(value,"isn_doesNotConsumePower") then
				return true
			end
		elseif config.getParameter("isn_powerPassthrough") then
			if world.callScriptedEntity(value,"isn_countPowerDevicesConnectedOnOutboundNode")>0 then
				return true
			end
		end
	end
	return false
end

function isn_countPowerDevicesConnectedOnOutboundNode()
	if storage.powerOutNode == nil then return 0 end
	local devicecount = 0
	local devicelist = isn_getAllDevicesConnectedOnNode(storage.powerOutNode,"output")
	if devicelist == nil then return 0 end
	for key, value in pairs(devicelist) do
		if world.callScriptedEntity(value,"isn_canRecievePower") then
			if not world.callScriptedEntity(value,"isn_doesNotConsumePower") then
				devicecount = devicecount + 1
			end
		end
	end
	return devicecount
end

function isn_sumPowerActiveDevicesConnectedOnOutboundNode()
	if storage.powerOutNode == nil then return 0 end
	local voltagecount = 0
	local batteries = 0
	local devicelist = isn_getAllDevicesConnectedOnNode(storage.powerOutNode,"output")
	if devicelist == nil then return 0 end
	
	--problem is here somewhere
	for key, value in pairs(devicelist) do
		if world.callScriptedEntity(value,"isn_canRecievePower") then
		
			if not world.callScriptedEntity(value,"isn_doesNotConsumePower") then
			
				if world.callScriptedEntity(value,"isn_isBattery") == true then
					
					if world.callScriptedEntity(value, "isn_recentlyDischarged") then batteries = batteries + 1 end
				--here...
				elseif world.callScriptedEntity(value,"isn_activeConsumption") then
					sb.logInfo("%s %s",key,value)
					local required = world.callScriptedEntity(value,"isn_requiredPowerValue", true)
					
					if required ~= nil then voltagecount = voltagecount + required end
					
				end
				
			end
		end
	end
	return voltagecount, batteries
end

function isn_sumOutboundPowerReq()
	if storage.powerOutNode == nil then return 0 end
	local voltagecount = 0
	local batteries = 0
	local devicelist = isn_getAllDevicesConnectedOnNode(storage.powerOutNode,"output")
	if devicelist == nil then return 0 end
	
	for key, value in pairs(devicelist) do
		local required = world.callScriptedEntity(value,"isn_requiredPowerValue", true)
		if required ~= nil then voltagecount = voltagecount + required end
		
	end
	return voltagecount, batteries
end

function isn_powerInit()
	storage.powercapacity = config.getParameter("isn_batteryCapacity")
	storage.voltage = config.getParameter("isn_batteryVoltage")
	storage.powerInNode = config.getParameter("isn_powerInNode")
	storage.powerOutNode = config.getParameter("isn_powerOutNode")
	storage.logicInNode = config.getParameter("logicInNode")
	storage.logicOutNode = config.getParameter("logicOutNode")
end
