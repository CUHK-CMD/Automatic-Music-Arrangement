package.path = package.path .. ";LuaMidi/src/?.lua"
local LuaMidi = require("LuaMidi")
local Object = require("Object")

local round = function (x, n)	-- n is the step
	n = n or 1
	
	if x % n >= n / 2 then
		return x - (x % n) + n
	else
		return x - (x % n)
	end
end

local shallowCopy = function(sourceObj)
	local obj = {}
	for k,v in pairs(sourceObj) do
		obj[k] = v
	end
	setmetatable(obj, getmetatable(sourceObj))
	
	return obj
end

local getEventAbsoluteTime = function(rawTrack, rawEvent, timeDivision)
	local foundEvent = false
	local accumulatedTime = 0
	
	for i, e in ipairs(rawTrack:get_events()) do
		local dt = e:get_timestamp()
		accumulatedTime = accumulatedTime + dt
		if (e == rawEvent) then
			foundEvent = true
			break
		end
	end
	
	assert(foundEvent, "Event not found in the track")
	return accumulatedTime / timeDivision
end
-------------------------------------------------

local MusicEditing = {}

-------------------------------------------------
---- Class: MusicEditing.Song
-------------------------------------------------
MusicEditing.Song = {
	getInfo = function (self)
		local str = "MusicEditing.Song:\n"
		for i, track in ipairs(self.tracks) do
			str = str .. string.format("\tTrack %s: %s\n", i, track)
			for j, event in ipairs(track.events) do
				str = str .. string.format("\t\tEvent %s: %s (%s %s)\n", j, event, event.time, event.rawEvent.type)
			end
		end
		return str
	end,
		
	addTrack = function (self, track)
		self.tracks[#self.tracks+1] = track
	end,
	
	removeTrack = function (self, track)
		local idx
		for i,trk in ipairs(self.tracks) do
			-- Assume: no duplicate track
			if (trk == track) then
				idx = i
				break
			end
		end
		table.remove(self.tracks, idx)
	end,
	
	getTracks = function (self)
		return self.tracks
	end,
	
	findTrackByName = function (self, name)
		for i,track in ipairs(self.tracks) do
			-- Assume: no duplicate track name
			if (track:getName() == name) then
				return track
			end
		end
		
		return nil
	end,
	
	getTimeDivision = function (self)
		return self.timeDivision
	end,
	
	getTimeSignature = function (self)
		return self.timeSignature
	end,
	
	setTimeSignature = function (self, timeSignature)
		self.timeSignature = timeSignature
	end,
	
	getTempo = function (self)
		return self.tempo
	end,
	
	setTempo = function (self, tempo)
		self.tempo = tempo
	end,
		
	export = function (self, filename, directory)
		local rawTracks = {}
		for i, track in ipairs(self.tracks) do
			track:sortEventsByTime()	-- not needed if every operation manage the order correctly, just in case it is not the case
			
			local rawTrack = LuaMidi.Track.new()
			-- rawTrack:add_events(LuaMidi.ProgramChangeEvent.new(1, track:getInstrument()))
			
			local rawEvents = {}
			local events = track:getEvents()
			local previousEventTime = 0
			for j, event in ipairs(events) do
				local time = event:getTime()
				local rawEvent = event:getRawEvent()
				
				if (rawEvent.type ~= "meta") then
					-- CAUTION: it causes a side effect (changed the original raw event's time)
					rawEvent:set_timestamp(round((time - previousEventTime) * self.timeDivision))
					
					previousEventTime = time
					
					rawEvents[#rawEvents+1] = rawEvent
					
					-- print(rawEvent, rawEvent.timestamp)
					-- for i,v in ipairs(LuaMidi.Util.num_to_var_length(rawEvent.timestamp)) do
						-- print("",i,v)
					-- end
				end
			end
			
			rawTrack:set_tempo(self.tempo)
			rawTrack:set_time_signature(self.timeSignature[1], self.timeSignature[2])
			rawTrack:add_events(rawEvents)
			rawTrack:set_name(track:getName())
			
			rawTracks[#rawTracks+1] = rawTrack
		end
		
		local writer = LuaMidi.Writer.new(rawTracks, self.timeDivision)
		writer:save_MIDI(filename, directory)
	end,
}
setmetatable(MusicEditing.Song, { __index = Object })	-- inherits Object
MusicEditing.Song.new = function (timeDivision, timeSignature, tempo)
	local self = {}
	self.timeDivision = timeDivision
	
	-- Assume: time signature and tempo is a constant
	-- Assume: default time signature is 4/4
	-- TODO: support varying time signature
	self.timeSignature = timeSignature or {4,4}
	self.tempo = tempo or 120
	self.tracks = {}
	
	return setmetatable(self, { __index = MusicEditing.Song })
end
MusicEditing.Song.buildFromFile = function(filename, ignoreNonNoteEvent)
	local originalTracks, timeDivision = LuaMidi.get_MIDI_tracks(filename);
	local self = MusicEditing.Song.new(timeDivision)
	
	local tempo
	local timeSignature

	for i, rawTrack in ipairs(originalTracks) do
		if tempo == nil then
			tempo = rawTrack:get_tempo()
		end
		
		if timeSignature == nil then
			timeSignature = rawTrack:get_time_signature()
		end
	
		local track = MusicEditing.Track.new(self, rawTrack:get_name())
		
		for j, rawEvent in ipairs(rawTrack:get_events()) do
			local absoluteTime = getEventAbsoluteTime(rawTrack, rawEvent, timeDivision)
			local event
			
			if rawEvent.type == "note_on" or rawEvent.type == "note_off" then
				event = MusicEditing.NoteOnOffEvent.buildFromRawEvent(self, absoluteTime, rawEvent)
				track:addEvent(event)
				
			elseif not ignoreNonNoteEvent then
				event = MusicEditing.Event.new(self, absoluteTime, rawEvent)
				track:addEvent(event)
			end
		end
		
		track:updateNoteOnOffEventPairs()
		self:addTrack(track)
	end
	
	if (tempo) then self:setTempo(tempo) end
	if (timeSignature) then self:setTimeSignature(timeSignature) end
	
	return self
end

-------------------------------------------------
---- Class: MusicEditing.Track
-------------------------------------------------
MusicEditing.Track = {
	addEvent = function (self, newEvent)
		-- TODO: use center of the table as theh starting point for better performance
		local insertPosition = 1
		local newEventTime = newEvent:getTime()
		for i,event in ipairs(self.events) do
			if newEventTime < event:getTime() then
				break
			end
			
			insertPosition = insertPosition + 1
		end
		table.insert(self.events, insertPosition, newEvent)
	end,
	removeEvent = function (self, eventPendingToBeRemoved)
		local idx
		for i,event in ipairs(self.events) do
			-- Assume: no duplicate event
			if (event == eventPendingToBeRemoved) then
				idx = i
				break
			end
		end
		table.remove(self.events, idx)
	end,
	getSong = function (self)
		return self.song
	end,
	getEvents = function (self)
		return self.events
	end,
	
	getName = function (self)
		return self.name
	end,
	setName = function (self, name)
		self.name = name
	end,
	
	getInstrument = function (self)
		return self.instrument
	end,
	setInstrument = function (self, instrument)
		self.instrument = instrument
	end,
	
	sortEventsByTime = function (self)
		table.sort(self.events, function(a,b) return a:getTime() < b:getTime() end)
	end,
	
	updateNoteOnOffEventPairs = function (self)
		--local originalTracks, timeDivision = LuaMidi.get_MIDI_tracks(filename);
	local self = MusicEditing.Song.new(timeDivision)
	
	local tempo
	local timeSignature
	--print(self.tracks)
		temp=0
		temp1=0
		A={}
		B={}
		--print(type(self))
		for i, rawTrack in ipairs(self.tracks) do
			--print("a")
			for j, rawEvent in ipairs(rawTrack:get_events()) do
				if (rawEvent.type=="note_on")
				then
					A[temp]=j
					temp=temp+1
				else
					B[temp1]=j
					temp1=temp1+1
				end
			--print(rawEvent.type, A[temp],B[temp1])
			end
		end
		temp=0
		temp1=0
		for i, rawTrack in ipairs(self.tracks) do
			for j,rawEvent in ipairs(rawTrack:get_events()) do
				if (event.rawtype=="note_on")
				then
					MusicEditing.rawEvent.setAnotherEvent(B[temp1])	
					print(event.rawEvent.anotherEvent)
					temp1=temp1+1
				else
					MusicEditing.rawEvent.setAnotherEvent(A[temp])
					print(event.rawEvent.anotherEvent)
					temp=temp+1	
				end
			end 
		end
	end,
	-- Assume: time signature is a constant
	-- TODO: support varying time signature
	getBarTime = function(self, barNumber)
		--print(self.song.timeSignature[1] * (4/self.song.timeSignature[2]) * (barNumber-1))
		return self.song.timeSignature[1] * (4/self.song.timeSignature[2]) * (barNumber-1) 
	end,

	getBarEvents = function(self, barNumber, barCount)
		local startTime = self:getBarTime(barNumber)
		--print(barNumber)
		--print(startTime)
		--print(barCount)
		local endTime = self:getBarTime(barNumber+barCount)
		--print(endTime)
		--print(barCount)	
		local events = {}
		
		for i, event in ipairs(self:getEvents()) do
			local eventTime = event:getTime()
			if (eventTime >= startTime and eventTime < endTime) then
				events[#events+1] = event
			end
		end
		
		return events
	end,
	
	getLength = function(self)
		if #self.events <= 0 then
			return 0
		else 
			return self.events[#self.events]:getTime()
		end
	end,
	
	-- ASSUME: time signature is a constant
	getBarCount = function(self)
		return math.ceil(self:getLength() / (self.song:getTimeSignature()[1] * (4/self.song:getTimeSignature()[2])))
	end,
	
	copyBarFrom = function(self, sourceTrack, barNumber, barCount, targetBarNumber)
		local timeOffset = self:getBarTime(targetBarNumber)
		--print(timeOffset)
		--print(targetBarNumber)
		local source = sourceTrack:getBarEvents(barNumber, barCount)
		--print(sourceTrack)
		for i, sourceEvent in ipairs(source) do
			local clonedEvent = sourceEvent:clone()
			--print(clonedEvent)
			clonedEvent:setTime(sourceEvent:getTime() - sourceTrack:getBarTime(barNumber) + timeOffset)
			self:addEvent(clonedEvent)
		end
		temp=0
		temp1=0
		A={}
		B={}
		for i,event in ipairs(self.events) do
			--print(i)
			if (event.rawEvent.type=="note_on")
			then
				A[temp]=event.time
				temp=temp+1
			end
			if (event.rawEvent.type=="note_off")
			then
				B[temp1]=event.time
				temp1=temp1+1
			end
			--print("b")
			--print(event.rawEvent.type)
			--print(type(event.time))
		end
		--print(type(A[i]))
		--print(self.song.timeDivision)
		for i=0,temp,1 do
			--print("i",i)
			for j=math.ceil(A[i]),math.floor(B[i]),1 do
				--print("j",j)
				--print(type(math.ceil(A[i])))
				if (j%4==0)
				then
					--NoteOnOffEvent.setAnotherEvent("note_on")
                    --NoteOnOffEvent.setAnotherEvent("note_off")
				end
				--updateNoteOnOffEventPairs()
			end
		end
		-- self:sortEventsByTime()
	end,
	
	
}
setmetatable(MusicEditing.Track, { __index = Object })	-- inherits Object
MusicEditing.Track.new = function (song, name, instrument)
	local self = {}
	self.song = song
	self.name = name or "Untitled Track"
	self.instrument = instrument or 0
	-- self.rawTrack = rawEvent
	self.events = {}
	
	return setmetatable(self, { __index = MusicEditing.Track })
end

-------------------------------------------------
---- Class: MusicEditing.Event
-------------------------------------------------
MusicEditing.Event = {
	getTime = function(self)
		return self.time
	end,
	
	setTime = function(self, time)
		self.time = time
	end,
	
	getRawEvent = function (self)
		return self.rawEvent
	end,
	
	clone = function (self)
		local obj = shallowCopy(self)
		obj.rawEvent = shallowCopy(self.rawEvent)
		obj.rawEvent:build_data()
		
		return obj
	end,
}
setmetatable(MusicEditing.Event, { __index = Object })	-- inherits Object
MusicEditing.Event.new = function (song, time, rawEvent)
	local self = {}
	self.song = song
	self.time = time	-- unit is quarter-note per bar, which is resolution-independent
	self.rawEvent = rawEvent
	
	return setmetatable(self, { __index = MusicEditing.Event })
end

-------------------------------------------------
---- Class: MusicEditing.NoteOnOffEvent
-------------------------------------------------
MusicEditing.NoteOnOffEvent = {
	getAnotherEvent = function (self)
		return self.anotherEvent
	end,
	
	setAnotherEvent = function (self, event)
		assert(event.rawEvent.type == "note_on" or event.rawEvent.type == "note_off", "The raw event is not a note-on nor note-off event")
		assert(self.rawEvent.type ~= event.rawEvent.type, "There must be one note-on and one note-off as a pair")
		self.anotherEvent = event
	end,
	
	getChannel = function (self)
		return self.rawEvent:get_channel()
	end,
	
	setChannel = function (self, channel)
		self.rawEvent:setChannel(channel)
	end,
	
	getPitch = function (self)
		return self.rawEvent:get_pitch()
	end,
	
	setPitch = function (self, pitch)
		self.rawEvent:set_pitch(pitch)
	end,
	
	getVelocity = function (self)
		return LuaMidi.Util.convert_velocity(self.rawEvent:get_velocity())
	end,
	
	setVelocity = function (self, velocity)
		self.rawEvent:set_velocity(LuaMidi.Util.revert_velocity(velocity))
	end,
}
setmetatable(MusicEditing.NoteOnOffEvent, { __index = MusicEditing.Event })	-- inherits MusicEditing.Event
MusicEditing.NoteOnOffEvent.new = function (song, time, type, channel, pitch, velocity)
	assert(type == "note_on" or type == "note_off", "Type must be \"note_on\" or \"note_off\"")

	local rawEvent
	if (type == "note_on") then 
		rawEvent =  LuaMidi.NoteOnEvent.new({
			pitch = pitch,
			velocity = LuaMidi.Util.revert_velocity(velocity),
			timestamp = 0,	-- timestamp of rawevent is not important before export and will be re-calculated when exporting
			channel = channel
		})
	elseif (type == "note_off") then
		rawEvent =  LuaMidi.NoteOffEvent.new({
			pitch = pitch,
			velocity = LuaMidi.Util.revert_velocity(velocity),
			timestamp = 0,	-- timestamp of rawevent is not important before export and will be re-calculated when exporting
			channel = channel
		})
	end

	local self = MusicEditing.Event.new(song, time, rawEvent)
	
	self.anotherEvent = nil
	
	return setmetatable(self, { __index = MusicEditing.NoteOnOffEvent })
end
MusicEditing.NoteOnOffEvent.buildFromRawEvent = function (song, time, rawEvent)
	local self = MusicEditing.Event.new(song, time, rawEvent)
	assert(self.rawEvent.type == "note_on" or self.rawEvent.type == "note_off", "The raw event is not a note-on nor note-off event")
	self.isNoteOn = self.rawEvent.type == "note_on"
	self.anotherEvent = nil
	return setmetatable(self, { __index = MusicEditing.NoteOnOffEvent })
end
	
-------------------------------------------------
---- Class: MusicEditing.ArrangementContext
-------------------------------------------------
MusicEditing.ArrangementContext = {
	getSectionNameByBar = function (self, bar)
		local section = -1
		for i, v in ipairs(self.sectionSeparation) do
			if bar >= v[2] then
				section = i
			else
				break
			end
		end
		
		return self.sectionSeparation[section][1]
	end
}
setmetatable(MusicEditing.ArrangementContext, { __index = Object })	-- inherits MusicEditing.Event
MusicEditing.ArrangementContext.new = function (song, melodyTrack, key, chordProgression, sectionSeparation, resourceSong)
	local self = {}
	local objMT = {
		__index = setmetatable({
			song = song,
			melodyTrack = melodyTrack,
			key = key,
			chordProgression = chordProgression,
			sectionSeparation = sectionSeparation,
			resourceSong = resourceSong
		}, {__index = MusicEditing.ArrangementContext}),
		
		__newindex = function (self, key, value)
			error("This object is readonly")
		end,
	}
	setmetatable(self, objMT)
	return self
end

-------------------------------------------------
---- (Static) Class: MusicEditing.Helper
-------------------------------------------------
local n2p = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local p2n = {}
for i,v in ipairs(n2p) do
	p2n[v] = i
end

MusicEditing.Helper = {
	pitchNameToNumber = function (name)
		return p2n[name]
	end,
	
	pitchNumberToName = function (number)
		return n2p[number]
	end,
}

--chord adaption

local notesTable = {
	{{"E4"}, {"D4"}, {"C4"}, {"D4"}},
	{"E4"}, {"E4"}, {"E4"}, {"E4"},
	{"D4"}, {"D4"}, {"D4"}, {"D4"},
	{"E4"}, {"G4"}, {"G4"}, {"G4"},
	{"E4"}, {"D4"}, {"C4"}, {"D4"},
	{"E4"}, {"E4"}, {"E4"}, {"E4"},
	{"D4"}, {"D4"}, {"E4"}, {"D4"},
	{"C4"}, {"C4"}, {"C4"}, {"C4"},
}

-- You can enter either notes with or without octaves (but they must be consistent)
-- e.g. SemitoneInterval('C', 'D') or SemitoneInterval('C4', 'D3')
SemitoneInterval = function (note1, note2)
	local temp1 = string.sub(note1, 1, 1)
	local temp2 = string.sub(note2, 1, 1)
	if string.sub(note1, 2, 2) == "#" then
		temp1 = temp1 .. "#"
	end
	if string.sub(note2, 2, 2) == "#" then
		temp2 = temp2 .. "#"
	end
	if string.match(note1, "[1234567890]") and string.match(note2, "[1234567890]") then
		local octave1 = tonumber(string.sub(note1, -1))
		local octave2 = tonumber(string.sub(note2, -1))
		return p2n[temp2] - p2n[temp1] + (octave2 - octave1) * 12
	else
		return p2n[temp2] - p2n[temp1]
	end
end

--print(SemitoneInterval('C4', 'D3'))

Transpose = function (note, semitoneInterval)
	local originalOctave = tonumber(string.sub(note, -1))
	local newOctave = originalOctave + semitoneInterval // 12
	if semitoneInterval < 0 then
		newOctave = originalOctave + (semitoneInterval - 1) // 12 + 1
	end

	local tempInterval = semitoneInterval % 12
	if semitoneInterval > 0 and p2n[string.sub(note, 1, -2)] + tempInterval > 12 then
		newOctave = newOctave + 1
	elseif semitoneInterval < 0 and p2n[string.sub(note, 1, -2)] + tempInterval - 12 < 1 then
		newOctave = newOctave - 1
	end

	local newNote = n2p[(p2n[string.sub(note, 1, -2)] + semitoneInterval - 1) % 12 + 1]

	return newNote .. tostring(newOctave)
end

--print(Transpose('C#4', -13))

ChordAdaption = function (bar, originalChord, newChord, transposeUp)

	local originalTonality = 'M'
	if string.find(originalChord, 'm') then
		originalTonality = 'm'
	end
	local newTonality = 'M'
	if string.find(newChord, 'm') then
		newTonality = 'm'
	end

	local originalChordNote = string.sub(originalChord, 1, 1)
	if string.sub(originalChord, 2, 2) == "#" then
		originalChordNote = originalChordNote .. "#"
	end

	local change3rd7th = {}
	if originalTonality == 'M' and newTonality == 'm' then
		table.insert(change3rd7th, {n2p[(p2n[originalChordNote] + 3) % 12 + 1], -1})
		if string.find(originalChord, '7') and string.find(newChord, '7') then
			table.insert(change3rd7th, {n2p[(p2n[originalChordNote] + 10) % 12 + 1], -1})
		end
	elseif originalTonality == 'm' and newTonality == 'M' then
		table.insert(change3rd7th, {n2p[(p2n[originalChordNote] + 2) % 12 + 1], 1})
		if string.find(originalChord, '7') and string.find(newChord, '7') then
			table.insert(change3rd7th, {n2p[(p2n[originalChordNote] + 9) % 12 + 1], 1})
		end
	end

	local semitoneInterval = 0
	if transposeUp then
		semitoneInterval = (SemitoneInterval(originalChord, newChord) + 12) % 12
	else
		semitoneInterval = (SemitoneInterval(originalChord, newChord) + 12) % 12 - 12
	end

	local newBar = {}
	for _,note in ipairs(bar) do
		local newNote
		if #change3rd7th > 0 and string.sub(note, 1, -2) == change3rd7th[1][1] then
			newNote = Transpose(note, semitoneInterval + change3rd7th[1][2]) 
		elseif #change3rd7th > 1 and string.sub(note, 1, -2) == change3rd7th[2][1] then
			newNote = Transpose(note, semitoneInterval + change3rd7th[2][2])
		else
			newNote = Transpose(note, semitoneInterval)
		end
		table.insert(newBar, newNote)
	end

	return newBar
	
end

-- Test

local barTemp = {
	{"D5","A4","F#4","D4"}, -- D
	{"D5","A4","F4","D4"}, -- Dm
	{"F#5","D5","B4","G4"}, -- G7
	{"F5","D5","A#4","G4"}, -- Gm7
}

local newBar
newBar = ChordAdaption(barTemp[1], "D", "C", false)
print("1", newBar[1], newBar[2], newBar[3], newBar[4])
newBar = ChordAdaption(barTemp[1], "D", "Cm", false)
print("2", newBar[1], newBar[2], newBar[3], newBar[4])
newBar = ChordAdaption(barTemp[2], "Dm", "C", false)
print("3", newBar[1], newBar[2], newBar[3], newBar[4])
newBar = ChordAdaption(barTemp[2], "Dm", "Cm", false)
print("4", newBar[1], newBar[2], newBar[3], newBar[4])
newBar = ChordAdaption(barTemp[3], "G7", "D7", true)
print("5", newBar[1], newBar[2], newBar[3], newBar[4])
newBar = ChordAdaption(barTemp[3], "G7", "Dm7", true)
print("6", newBar[1], newBar[2], newBar[3], newBar[4])
newBar = ChordAdaption(barTemp[4], "Gm7", "D7", true)
print("7", newBar[1], newBar[2], newBar[3], newBar[4])
newBar = ChordAdaption(barTemp[4], "Gm7", "Dm7", true)
print("8", newBar[1], newBar[2], newBar[3], newBar[4])

-------------------------------------------------
return MusicEditing
