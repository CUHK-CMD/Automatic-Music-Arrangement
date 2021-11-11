local MusicEditing = require "MusicEditing"
local Object = require "Object"

local Helper = MusicEditing.Helper

local p2n = Helper.pitchNameToNumber
local n2p = Helper.pitchNumberToName
local chords = {}
local chordsInterval = {
	{"M", 0, 4, 7},     -- M
	{"7", 0, 4, 7, 11}, -- 7
	{"m", 0, 3, 7},     -- m
	{"o", 0, 3, 6},     -- o
	{"+", 0, 4, 8}      -- +
}

for i = 1,12 do
	for _,intervalTable in ipairs(chordsInterval) do
		local tempChord = {n2p(i)..intervalTable[1]}
		for j,interval in ipairs(intervalTable) do
			if j > 1 then
				table.insert(tempChord, (i - 1 + interval) % 12 + 1)
			end
		end
		table.insert(chords, tempChord)
	end
end

local numberOfChords = #chords

--for i = 1,numberOfChords do
--	if #chords[i] > 4 then
--		print(chords[i][1], chords[i][2], chords[i][3], chords[i][4], chords[i][5])
--		print("", n2p(chords[i][2]), n2p(chords[i][3]), n2p(chords[i][4]), n2p(chords[i][5]))
--	else
--		print(chords[i][1], chords[i][2], chords[i][3], chords[i][4])
--		print("", n2p(chords[i][2]), n2p(chords[i][3]), n2p(chords[i][4]))
--	end
--end

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

for i = 1,24 do
	print(scales[i][1], scales[i][2], scales[i][3], scales[i][4], scales[i][5], scales[i][6], scales[i][7], scales[i][8])
end

function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

-- Harmonize all notes inside a table and return the chord

function Harmonize (notesTable)

	local scores = {}
	
	for _ = 1,numberOfChords do
		table.insert(scores, 0)
	end

	for i = 1,numberOfChords do
		local tempChord = chords[i]
		table.remove(tempChord, 1)
		local match = 0
		local appeared = {}
		for _,_ in ipairs(tempChord) do
			table.insert(appeared, 0)
		end
		for _,note in ipairs(notesTable) do
			local notePitch = note:getPitch() % 12 + 1
			for j,chordNotePitch in ipairs(tempChord) do
				if notePitch == chordNotePitch then
					if j == 1 then
						match = match + 2
					elseif j == 2 then
						match = match + 1
					elseif j == 3 then
						match = match + 2
					elseif j == 4 then
						match = match + 1
					end
					appeared[j] = 1
				end
			end
		end
		local appearSum = appeared[1] + appeared[2] + appeared[3] + appeared[4]
		table.insert(scores, appearSum * match)
	end
	
	local maxChord = 1
	for i = 2,numberOfChords do
		if scores[i] > scores[maxChord] then
			maxChord = i
		end
	end
	local tempChord = chords[maxChord]
	table.remove(tempChord, 1)
	return tempChord

end

local MusicAnalysis = {}

MusicAnalysis.MusicAnalyser = {
	estimateKey = function (self)
		-- TO BE IMPLEMENTED
		local scores = {
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		}

		-- Q1: To save all notes of bars in the music as a notesTable
		-- notesTable = self:???
		
		for _,note in ipairs(notesTable) do
			local notePitch = note:getPitch() % 12 + 1
			for j,scale in ipairs(scales) do
				local appeared = false
		
				-- Calculate the score measuring the matchability of the notes with a scale
				for k,scaleNote in ipairs(scale) do
					if notePitch == n2p(scaleNote) then
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
		local maxKey = 1
		for i = 2,24 do
			if scores[i] > scores[maxKey] then
				maxKey = i
			end
		end
		local key = scales[maxKey]
		table.remove(key, 1)
		return key
	end,
	
	estimateChordProgression = function (self)
		-- TO BE IMPLEMENTED

		-- Q2: To save all notes of each bar in the music as a barTable
		-- barTable = self:???

		local chordProgression = {}

		for _,bar in ipairs(barTable) do
			if type(bar[1]) == "table" then
				local tempChordProgression = {}
				for _,barSegment in ipairs(bar) do
					table.insert(tempChordProgression, Harmonize(barSegment))
				end
				table.insert(chordProgression, tempChordProgression)
			else
				table.insert(chordProgression, Harmonize(bar))
			end
		end

		return chordProgression
	end
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
