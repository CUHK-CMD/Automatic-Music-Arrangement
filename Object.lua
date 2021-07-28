-------------------------------------------------
---- (Abstract) Class: MusicEditing.Object
-------------------------------------------------
local Object = {
	-- ASSUME: __index is always table instead of function, and the table is this class or a class derived from this class
	getClass = function (self)
		return getmetatable(self).__index
	end,
	
	-- ASSUME: __index is always table instead of function
	-- CAUTION: this function can be slow when there are lots of classes in the namespace
	getClassName = function (self, namespace)
		assert(namespace and type(namespace) == "table", "Invalid namespace")
	
		local class = self:getClass()
		for k,v in pairs(namespace) do
			if (v == class) then
				return k
			end
		end
		
		error("This class does not exist in the namespace")
	end,
	
	-- ASSUME: __index is always table instead of function
	isDerivedFrom = function (self, class)
		local metatable = getmetatable(self)
		
		while(metatable and metatable.__index) do
			if (metatable.__index == class) then
				return true
			end
			
			metatable = getmetatable(metatable.__index)
		end
		
		return false
	end,
}

return Object
