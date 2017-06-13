require "/scripts/kheAA/transferUtil.lua"
storage={}

function init()
	transferUtil.init()
	storage.inContainers={}
	storage.outContainers={}
end

function update(dt)
	deltatime=(deltatime or 0)+dt
	if deltatime < 1 then
		return
	end
	deltatime=0
	transferUtil.updateInputs(storage.itemInNode);
	transferUtil.updateOutputs(storage.itemOutNode);
	if storage.logicOutNode then
		object.setOutputNodeLevel(storage.logicOutNode,util.tableSize(storage.outContainers))
	end
end
