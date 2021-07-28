local MusicEditing = require "MusicEditing"

local Song = MusicEditing.Song
local Track = MusicEditing.Track
local Event = MusicEditing.Event
local NoteOnOffEvent = MusicEditing.NoteOnOffEvent
local ArrangementContext = MusicEditing.ArrangementContext

local style = {
	name = "Style Example",
	author = "Charles Ho",
	version = "1.0",
	-- tempo = 120,
	-- signature = {4,4},
	-- scales = {"major", "minor"},
	-- sections = {"intro", "verse", "chrous", "outro"},
	resourceFilename = "style-resources.mid",
	
	arrange = function (arrangementContext)
		local melodyTrack = arrangementContext.melodyTrack
		local melodyBarCount = melodyTrack:getBarCount()
	
		local leadTrack = Track.new(arrangementContext.song, "Lead")
		leadTrack:copyBarFrom(melodyTrack, 1, melodyBarCount, 1)
		
		arrangementContext.song:addTrack(leadTrack)
		
		local drumTrack = Track.new(arrangementContext.song, "Drum")
		local resourceDrumTrack = arrangementContext.resourceSong:findTrackByName("Drum")
		
		-- ASSUME: section starts with the beginning of a odd bar
		for i = 1, melodyBarCount do
			local sectionName = arrangementContext:getSectionNameByBar(i)
			
			if sectionName == "intro" then
				local clipBarCount = 2
				drumTrack:copyBarFrom(resourceDrumTrack, 5 + (i-1) % clipBarCount, 1, i)
				
			elseif sectionName == "verse" then
				local clipBarCount = 2
				drumTrack:copyBarFrom(resourceDrumTrack, 3 + (i-1) % clipBarCount, 1, i)
				
			elseif sectionName == "chrous" then
				local clipBarCount = 2
				drumTrack:copyBarFrom(resourceDrumTrack, 7 + (i-1) % clipBarCount, 1, i)
			
			elseif sectionName == "outro" then	-- ASSUME: outro ends within a bar
				-- local clipBarCount = 0.5
				drumTrack:copyBarFrom(resourceDrumTrack, 9, 0.5, i)
				drumTrack:copyBarFrom(resourceDrumTrack, 9, 0.5, i + 0.5)
				drumTrack:copyBarFrom(resourceDrumTrack, 1, 1/8, i+1)
			end
		end
		
		arrangementContext.song:addTrack(drumTrack)
	end,
}

return style