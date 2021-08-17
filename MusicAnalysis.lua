local MusicEditing = require "MusicEditing"
local Object = require "Object"

local Helper = MusicEditing.Helper

-- processed song template (I think main.lua will pass to me but I don't know the format yet)

local timeSignature = 4

local notesTable = {
	{"E4"}, {"D4"}, {"C4"}, {"D4"},
	{"E4"}, {"E4"}, {"E4"}, {"E4"},
	{"D4"}, {"D4"}, {"D4"}, {"D4"},
	{"E4"}, {"G4"}, {"G4"}, {"G4"},
	{"E4"}, {"D4"}, {"C4"}, {"D4"},
	{"E4"}, {"E4"}, {"E4"}, {"E4"},
	{"D4"}, {"D4"}, {"E4"}, {"D4"},
	{"C4"}, {"C4"}, {"C4"}, {"C4"},
}

-- processed song template end

local p2n = Helper.pitchNameToNumber
local n2p = Helper.pitchNumberToName

-- Table of chords
-- I assume there are no inversions or 7th chords first
local numberOfChords = 7
local chords = {
	{"C",  p2n("C"), p2n("E"), p2n("G")},
	{"Dm", p2n("D"), p2n("F"), p2n("A")},
	{"Em", p2n("E"), p2n("G"), p2n("B")},
	{"F",  p2n("F"), p2n("A"), p2n("C")},
	{"G",  p2n("G"), p2n("B"), p2n("D")},
	{"Am", p2n("A"), p2n("C"), p2n("E")},
	{"Bo", p2n("B"), p2n("D"), p2n("F")},
}

-- Table of scales
-- Used for estimateKey
-- Can be simply initialized with the root note and the interval of major minor scales 
local intervalsMajor = {0, 2, 4, 5, 7, 9, 11}
local intervalsMinor = {0, 2, 3, 5, 7, 8, 11}

local scales = {
	{},	{},	{},	{},	{},	{},	{},	{},	{},	{},	{},	{},
	{},	{},	{},	{},	{},	{},	{},	{},	{},	{},	{},	{}
}

for i in ipairs(scales) do
	if i <= 12 then
		scales[i][1] = n2p(i).."M"
		for j = 2,8 do
			scales[i][j] = n2p((i - 1 + intervalsMajor[j - 1]) % 12 + 1)
		end
	else
		scales[i][1] = n2p(i - 12).."m"
		for j = 2,8 do
			scales[i][j] = n2p((i - 1 + intervalsMinor[j - 1]) % 12 + 1)
		end
	end
end

--for i = 1,8 do
--	print(scales[22][i])
--end

function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

local MusicAnalysis = {}

local progression = {}

-- Harmonize bar by bar
function Harmonize (bar, frequency, isFirst)

	local barSegment = {}
	local beatLeft = bar
	local barSize = #bar
	while barSize > 0 do
		for i=1,frequency do
			if bar[1] then
				for _,note in bar[1] do
					table.insert(barSegment, note)
				end
				table.remove(beatLeft, 1)
				barSize = barSize - 1
			else
				break
			end		
		end
		-- Match
		local chords = {}
		-- Match end
		if isFirst then
			local progression = {}
			table.insert(progression, chords)
		end
		Harmonize(beatLeft, frequency, false)
	end

	-- Group the notes of beats with a certain number
	-- For beatGroup == n, we concat all notes of the first n beats as a subset
	-- We harmonize this subset and pass the remain
	local beatGroup = frequency
	
	while #bar >= frequency do
		
	end
	return 
end

MusicAnalysis.MusicAnalyser = {
	estimateKey = function (self)
		-- TO BE IMPLEMENTED
		local scores = {
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		}
		for _,notes in ipairs(notesTable) do
			for _,note in ipairs(notes) do
				local temp = string.sub(note, 1, string.len(note) - 1)
				--print(temp)
				for j,scale in ipairs(scales) do
					local appeared = false
			
					-- Calculate the score measuring the matchability of the notes with a scale
					for k,scaleNote in ipairs(scale) do
						if temp == scaleNote then
							appeared = true
							-- If the note is the key note (e.g. C of CM/m), 4 marks gained
							if k == 2
							then
								scores[j] = scores[j] + 3
							-- If the note is a 3rd note (e.g. E of CM, D# of Cm), subdominant (e.g. F of CM/m)
							-- or dominant (e.g. G of CM/m), 2 marks gained
							elseif k >= 4 and k <= 6
							then
								scores[j] = scores[j] + 2
							-- If the note does not belong to the above attributes but belongs to the scale,
							-- 1 mark gained
							else
								scores[j] = scores[j] + 1
							end
						end
					end
					-- If the note does not belong to the scale, 1 mark deducted
					if appeared == false then
						scores[j] = scores[j] - 1
					end
				end
			end
		end
		--for j in ipairs(scales) do
		--	print(scales[j][1], scores[j])
		--end
		local maxKey = 1
		for i = 2,24 do
			if scores[i] > scores[maxKey] then
				maxKey = i
			end
		end
		return scales[maxKey][1]
	end,
	
	estimateChordProgression = function (self)
		-- TO BE IMPLEMENTED

		-- By default, we count the beat by quarter note, so beat per bar is equals to the timeSignature
		-- For songs which timeSignature is a small, you might not want to count the beat by quarter note,
		-- so we can set beatPerBar be the multiple of timeSignature
		-- Notes:
		-- This number is actually used in the preprocessing part, which is not implemented at this moment
		local beatPerBar = timeSignature

		-- The starting beat of the first bar, by default is 1
		local startingBeat = 1

		-- The frequency of harmonizing the notes, beat as unit
		-- e.g. If we want to harmonize the notes beat by beat, we can set frequency = 1
		--      If we want to harmonzie the notes bar by bar, we can set frequency = timeSignature
		-- Notes:
		-- We will try all combinations by grouping the notes of beats with multiple of frequency
		-- e.g. For timeSignature == 4 and frequency == 1, we will group the notes as:
		--          {1, 1, 1, 1}, {1, 1, 2}, {1, 2, 1}, {1, 3},
		--          {2, 1, 1}, {2, 2},
		--          {3, 1},
		--          {4}
		--      For timeSignature == 4 and frequency == 2, we will group the notes as:
		--          {2, 2}, {4}
		-- Therefore, frequency should be a factor of timeSignature (at the current version)
		-- And you might see, for frequency == 1, the combination of {2, 2} still appear, which means
		-- you can simply set frequency = 1 to get all combinations (although it might be slower)
		local frequency = 1

		local i = 1
		local beatNum = #notesTable
		local tempBar = {}
		local chordProgression = {}
		while i <= beatNum do
			table.insert(tempBar, notesTable[i])

			if (startingBeat + i - 1) % beatPerBar == 0 or i == beatNum then
				Harmonize(tempBar, frequency, true)
				tempBar = {}
			end
		end

	end,
}
setmetatable(MusicAnalysis.MusicAnalyser, { __index = Object })	-- inherits Object
MusicAnalysis.MusicAnalyser.new = function (melodyTrack)
	local self = {
		melodyTrack = melodyTrack
	}
	return setmetatable(self, { __index = MusicAnalysis.MusicAnalyser })
end

-- Debug area begins

-- Debug area ends

return MusicAnalysis
