local MusicEditing = require "MusicEditing"
local Object = require "Object"

local MusicAnalysis = {}

MusicAnalysis.MusicAnalyser = {
	estimateKey = function (self)
		-- TO BE IMPLEMENTED
	end,
	
	estimateChordProgression = function (self)
		-- TO BE IMPLEMENTED
	end,
}
setmetatable(MusicAnalysis.MusicAnalyser, { __index = Object })	-- inherits Object
MusicAnalysis.MusicAnalyser.new = function (melodyTrack)
	local self = {
		melodyTrack = melodyTrack
	}
	return setmetatable(self, { __index = MusicAnalysis.MusicAnalyser })
end

return MusicAnalysis