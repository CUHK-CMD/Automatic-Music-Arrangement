local MusicEditing = require "MusicEditing"
local MusicAnalysis = require "MusicAnalysis"

local Song = MusicEditing.Song
local Track = MusicEditing.Track
local Event = MusicEditing.Event
local NoteOnOffEvent = MusicEditing.NoteOnOffEvent
local ArrangementContext = MusicEditing.ArrangementContext
local Helper = MusicEditing.Helper

local helporversion = false
local songExport = nil
local melodySong = nil
local arguments = {input = nil, style = nil, output = nil, settings = nil}
local style = nil
local settings = nil

function readFlags(flag, argnum) -- called by readArguments(), help to process the flags & cmds one by one
	if (flag == "-i" or flag == "--input")
	then
		flag = "input"
		if (arguments[flag] == nil)
		then
			arguments[flag] = arg[argnum+1]
			
			if (not pcall(Song.buildFromFile, arguments[flag]))
			then
				print("Error: " .. arguments[flag] .. " not found or the file is invalid!")
				return false
			end
			melodySong = Song.buildFromFile(arguments[flag])
			argnumber = argnumber + 1
		else
			print("Repeated input flag!")
			return false
		end
			
	elseif (flag == "-s" or flag == "--style")
	then
		flag = "style"
		if (arguments[flag] == nil)
		then
			arguments[flag] = arg[argnum+1]
			if (not pcall(dofile, arguments[flag]))
			then
				print("Error! " .. arguments[flag] .. " not found or the file is invalid!")
				return false
			end
			style = dofile(arguments[flag]) 
			argnumber = argnumber + 1
		else
			print("Repeated style flag!")
			return false
		end
	elseif (flag == "-o" or flag == "--output")
	then
		flag = "output"
		if (arguments[flag] == nil)
		then
			arguments[flag] = arg[argnum+1]
			songExport = arguments[flag]
			argnumber = argnumber + 1
			--print("o")
		else
			print("Repeated output flag!")
			return false
		end
	elseif (flag == "-c" or flag == "--settings")
	then
		flag = "settings"
		if (arguments[flag] == nil)
		then
			arguments[flag] = arg[argnum+1]
			if (not pcall(dofile, arguments[flag]))
			then
				print("Error: " .. arguments[flag] .. " not found or the file is invalid!")
				return false
			end
			settings = dofile(arguments[flag])
			if (settings.sectionSeparation == nil)
			then
				print("sectionSeparation is missing! It is compulsory!")
				return false
			end
			argnumber = argnumber + 1
			--print("c")
		else
			print("Repeated settings flag!")
			return false
		end
	elseif (flag == "-h" or flag == "-v" or flag == "--version" or flag == "--help")
	then
		helporversion = true
		if (argnum ~= 1 or arg[2] ~= nil)
		then
			print("Please use " .. flag .. " flag in single argument!")
			return false
		elseif (flag == "-h" or flag == "--help")
		then
			print("-h, --help (Please use it in a single argument)\n",
			"-v, --version (Please use it in a single argument)\n",
			"-i, --input MELODY_FILE_PATH\n",
			"-s, --style STYLE_FILE_PATH\n",
			"-o, --output OUTPUT_FILE_PATH\n",
			"-c, --settings SETTINGS_FILE_PATH\n",
			"Example: Lua main.lua -i melody.mid -o arrangement.mid -s style.lua -c settings.lua")
			return false
		else
			print("Version 1.0")
			return false
		end
	else
		print("This flag is not available!")
		return false
	end
	return true
end

function readArguments() -- 2nd function it will read the FULL arguments in the cmd, and split the flag to let readFlags() do it
	if (arg[9] ~= nil)
	then
		print("Too much arguments!")
		return false
	elseif (arg[1] == nil)
	then
		print("Please input proper argument for input and output! Use command \"-h\" or \"--help\" for more details")
		return false
	else
		argnumber = 1
		while (argnumber <= 8 and arg[argnumber] ~= nil)
		do
			local canContinue = readFlags(arg[argnumber], argnumber)
			argnumber = argnumber + 1
			if (not canContinue)
			then
				return false
			end
		end
	end

	if (not (arguments["input"] ~= nil and arguments["style"] ~= nil and arguments["output"] ~= nil and arguments["settings"] ~= nil))
	then
		if (helporversion == false)
		then
			if (arguments["input"] == nil)
			then
				print("Input is missing!")
			end
			if (arguments["output"] == nil)
			then
				print("Output is missing!")
			end
			if (arguments["style"] == nil)
			then
				print("Style file is missing!")
			end
			if (arguments["settings"] == nil)
			then
				print("Settings file is missing!")
			end
			return false
		end
	end
	return true
end

function mainRun()	--main part for the running of program, after checking it is error-free

	-- local melodySong = Song.buildFromFile("country-road-melody-short.mid")
	-- local melodySong = Song.buildFromFile("Debug/tempo-test.mid")
	-- local melodySong = Song.buildFromFile("c_major_scale.mid")
	-- local melodySong = Song.buildFromFile("offset-2.mid")
	local melodyTrack = melodySong:getTracks()[#melodySong:getTracks()]
	
	local analyser = MusicAnalysis.MusicAnalyser.new(melodyTrack)
	local key = analyser:estimateKey()
	local chordProgression = analyser:estimateChordProgression()
	
	-- local n2p = Helper.pitchNumberToName
	-- for i = 1, #chordProgression do
		-- for j = 1, #chordProgression[i] do
			-- io.write(n2p(chordProgression[i][j]) .. "\t")
		-- end
		-- io.write("\n")
	-- end

	local song = Song.new(
		melodySong:getTimeDivision(),
		settings.timeSignature or melodySong:getTimeSignature(),
		settings.tempo or melodySong:getTempo()
	)

	local p2n = Helper.pitchNameToNumber

	local chordG = { p2n("G"), p2n("B"), p2n("D") }
	local chordEm = { p2n("E"), p2n("G"), p2n("B") }
	local chordD = { p2n("D"), p2n("F#"), p2n("A") }
	local chordC = { p2n("C"), p2n("E"), p2n("G") }
	local chordF = { p2n("F"), p2n("A"), p2n("C") }
	local chordC7 = { p2n("C"), p2n("E"), p2n("G"), p2n("A#") }

	local arrangementContext = ArrangementContext.new(
		song,
		melodyTrack,
		settings.key or key,
		settings.chordProgression or chordProgression,
		settings.sectionSeparation,
		Song.buildFromFile(style.resourceFilename)
	)

	style.arrange(arrangementContext)
	song:export(arguments["output"])
	print("Successfully saved as " .. arguments["output"] .. ".")
end

--  Program Execution
if (readArguments() == true)
then
	mainRun()
end
