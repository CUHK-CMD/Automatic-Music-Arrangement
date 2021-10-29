local MusicEditing = require "MusicEditing"
local MusicAnalysis = require "MusicAnalysis"

local Song = MusicEditing.Song
local Track = MusicEditing.Track
local Event = MusicEditing.Event
local NoteOnOffEvent = MusicEditing.NoteOnOffEvent
local ArrangementContext = MusicEditing.ArrangementContext
local Helper = MusicEditing.Helper

------------------------------------------------------------
-- The following lines of code is only for demonstration
-- Please remove them and write a proper version
------------------------------------------------------------
local style = dofile("test-style.lua")

local melodySong = Song.buildFromFile("style-resources.mid")
-- local melodySong = Song.buildFromFile("Debug/tempo-test.mid")
-- local melodySong = Song.buildFromFile("c_major_scale.mid")
-- local melodySong = Song.buildFromFile("offset-2.mid")
local melodyTrack = melodySong:getTracks()[#melodySong:getTracks()]

-- print(melodySong:getTimeDivision())
local song = Song.new(
	melodySong:getTimeDivision(),
	melodySong:getTimeSignature(),
	melodySong:getTempo()
)

local p2n = Helper.pitchNameToNumber

local chordG = { p2n("G"), p2n("B"), p2n("D") }
local chordEm = { p2n("E"), p2n("G"), p2n("B") }
local chordD = { p2n("D"), p2n("F#"), p2n("A") }
local chordC = { p2n("C"), p2n("E"), p2n("G") }
local chordCm = { p2n("C"), p2n("D#"), p2n("G") }
local chordF = { p2n("F"), p2n("A"), p2n("C") }
local chordC7 = { p2n("C"), p2n("E"), p2n("G"), p2n("A#") }

local arrangementContext = ArrangementContext.new(
	song,
	melodyTrack,
	{ p2n("A"), p2n("B"), p2n("C#"), p2n("D"), p2n("E"), p2n("F#"), p2n("G#") },
	{
		chordG, chordEm, chordD, chordC, 
		
		chordG, chordEm, chordD, {chordC, chordG},
		chordG, chordEm, chordD, {chordC, chordG},
		
		chordG, chordD, chordEm, chordC,
		chordG, chordD, chordC, chordG,
		
		chordG
	},
	{
		{"intro", 1},
		{"verse", 5},
		{"chrous", 13},
		{"outro", 20},
		{"_finish", 21},
	},
	Song.buildFromFile(style.resourceFilename)
)
-- melodySong:export("test.mid")
-- style.arrange(arrangementContext)
ChordAdaption(melodyTrack:getBarEvents(1, 4), chordC, chordEm)
melodySong:export("test.mid")