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
local helporversion = false
local arguments = {input, style, output, settings}
function readCommand(flag, argnum)
	if (flag == "-i" or flag == "--input")
		then
			flag = "input"
			if (arguments[flag] == nil)
			then
				arguments[flag] = arg[argnum+1]
				local melodySong = Song.buildFromFile(arguments[flag])
				argnumber = argnumber + 1
				--print("i")
			else
				print("Repeated input flag!")
			end
			
		else if (flag == "-s" or flag == "--style")
		then
			flag = "style"
			if (arguments[flag] == nil)
			then
				arguments[flag] = arg[argnum+1]
				local style = dofile(arguments[flag]) 
				argnumber = argnumber + 1
				--print("s")
			else
				print("Repeated style flag!")
			end
		else if (flag == "-o" or flag == "--output")
		then
			flag = "output"
			if (arguments[flag] == nil)
			then
				arguments[flag] = arg[argnum+1]
				local songExport = arguments[flag]
				argnumber = argnumber + 1
				--print("o")
			else
				print("Repeated output flag!")
			end
		else if (flag == "-c" or flag == "--settings")
		then
			flag = "settings"
			if (arguments[flag] == nil)
			then
				arguments[flag] = arg[argnum+1]
				argnumber = argnumber + 1
				--print("c")
			else
				print("Repeated settings flag!")
			end
		else if (flag == "-h" or flag == "-v" or flag == "--version" or flag == "--help")
		then
			helporversion = true
			if (argnum ~= 1 or arg[2] ~= nil)
			then
				print("Please use this flag in single argument!")
			else if (flag == "-h" or flag == "--help")
				then
					print("-h, --help\n",
					"-v, --version\n",
					"-i, --input MELODY_FILE_PATH\n",
					"-s, --style STYLE_FILE_PATH\n",
					"-o, --output OUTPUT_FILE_PATH\n",
					"-c, --settings SETTINGS_FILE_PATH\n",
					"example: Lua main.lua -i melody.mid -o arrangement.mid -s style.lua -c settings.lua")
				else
					print("Version 0")
				end
			end
		else
			print("This flag is not available!")
	end end end end end
	
end

if (arg[9] ~= nil)
	then
	print("Too much arguments!")
	else if (arg[1] == nil)
		then
		print("Please input proper argument for input and output! Use command "-h" or "-help" for more details")
		else
		argnumber = 1
		while (argnumber <= 8 and arg[argnumber] ~= nil)
		do
			readCommand(arg[argnumber], argnumber)
			argnumber = argnumber + 1
		end
	end
end

if (arguments[input] ~= nil and arguments[style] ~= nil and arguments[output] ~= nil and arguments[settings] ~= nil)
then
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
style.arrange(arrangementContext)
song:export(arguments[output])
print("Successfully saved as ", arguments[output])
else
	if (helporversion == false)
		if (arguments[input] == nil)
			print("Input is missing!")
		end
		if (arguments[output] == nil)
			print("Output is missing!")
		end
		if (arguments[style] == nil)
			print("Style file is missing!")
		end
		if (arguments[settings] == nil)
			print("Setting file is missing!")
		end
	end
end