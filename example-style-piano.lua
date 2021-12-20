local MusicEditing = require "MusicEditing"

local Song = MusicEditing.Song
local Track = MusicEditing.Track
local Event = MusicEditing.Event
local NoteOnOffEvent = MusicEditing.NoteOnOffEvent
local ArrangementContext = MusicEditing.ArrangementContext

local style = {
	name = "Example Style Piano",
	author = "Charles Ho",
	version = "1.0",
	resourceFilename = "style-resources-piano.mid",
	
	arrange = function (arrangementContext)
	
		local p2n = MusicEditing.Helper.pitchNameToNumber
		local chordC = { p2n("C"), p2n("E"), p2n("G") }
	
		local melodyTrack = arrangementContext.melodyTrack
		local melodyBarCount = melodyTrack:getBarCount()
	
		local leadTrack = Track.new(arrangementContext.song, "Lead")
		leadTrack:copyBarFrom(melodyTrack, 1, melodyBarCount, 1)
		
		arrangementContext.song:addTrack(leadTrack)
		
		-----------------------------------------------------
		local pianoTrack = Track.new(arrangementContext.song, "Piano")
		local resourcePianoTrack = arrangementContext.resourceSong:findTrackByName("Piano")
	
		for i = 1, melodyBarCount do
			local chord = arrangementContext.chordProgression[i]
			pianoTrack:copyBarFrom(resourcePianoTrack, 1, 1, i)
			pianoTrack:adaptChord(i, 1, chordC, chord)
		end
		
		local chord = arrangementContext.chordProgression[melodyBarCount]
		pianoTrack:copyBarFrom(resourcePianoTrack, 2, 1, melodyBarCount+1)
		pianoTrack:adaptChord(melodyBarCount+1, 1, chordC, chord)
		
		arrangementContext.song:addTrack(pianoTrack)
	end,
}

return style