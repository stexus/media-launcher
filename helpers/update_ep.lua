local utils = require('mp.utils')
local msg = require('mp.msg')

--JSON read/write adopted from gist
-- read JSON file if exists
--      check folder where media is being played. grab ep and increment
-- otherwise create one
local medialist = os.getenv('HOME') .. '/.medialist.json'
local mediaDir = '/mnt/misc-ssd/Anime/'
local dir = utils.getcwd()




-- JSON loading and saving
local JSON = {}
JSON.saveTable = function(path, v)
    local file = io.open(path, "w+")
    local contents = utils.format_json(v)
    file:write(contents)
    io.close(file)
end

JSON.loadTable = function(path)
    local contents = ""
    local myTable = {}
    local file = io.open(path,"r")
    if file then
        local contents = file:read("*a")
        myTable = utils.parse_json(contents) or {}
        io.close(file)
    else
        JSON.saveTable(path)
    end
    return myTable
end


-- 40149617/split-string-with-specified-delimiter-in-lua
function split(s, sep)
    local fields = {}
    
    local sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    -- changing such that it is a dictionary
    local i = 0
    string.gsub(s, pattern, function(c) 
        fields[#fields + 1] = c
    end)
    return fields
end

local function subprocess(command, stdin)
    return mp.command_native({
            name = 'subprocess',
            playback_only = false,
            capture_stdout = true,
            stdin_data = stdin,
            args = command
        })
end
local handle_seek, handle_pause, timer, curr_list, title, curr_ep
local function get_ep()
    -- using mostly bash to be absolutely consistent with python script
    local filename = mp.get_property('filename')
    local commands = {'find', mediaDir..title, '-type', 'f', '-name', '*.mkv'}
    local result = subprocess(commands)
    local line
    if result.status == 0 then 
        local sorted = subprocess({'sort'}, result.stdout)
        line = subprocess({'grep', '-Fn', filename}, sorted.stdout)
    end
    if line.status == 0 then
        local end_index = line.stdout:find(':')
        local ep = line.stdout:sub(0, end_index - 1)
        return tonumber(ep)
    end
    return 0
end


local function kill_timer()
    if timer then
        timer:kill()
        timer = nil
        msg.info('timer stopped')
    end
end
local function killall()
    kill_timer()
    mp.unobserve_property(handle_pause)
    mp.unregister_event(handle_seek)
end

local function complete_ep(ep)
    msg.info('episode completed')
    killall()
    curr_list[title] = ep or curr_ep
    JSON.saveTable(medialist, curr_list)
    mp.osd_message('Marked completed: '..curr_list[title], 1)
end

--increment and write to JSON when 85% passed or last chapter crossed
--last chapter passed (unless before 85%)
--adapted from @gim-
local function start_timer()
    local threshold = mp.get_property('duration')
    local curr_time = mp.get_property('time-pos')
    threshold = threshold * 0.85 
    local until_threshold = math.max(threshold - curr_time, 0)
    timer = mp.add_timeout(until_threshold, complete_ep)
    msg.info('time left: ' .. until_threshold)
end
handle_pause = function(_, paused)
    if paused then kill_timer()
    else start_timer() end
end

handle_seek = function()
    if not timer then return end
    kill_timer()
    start_timer()
end

local function extract_title()
    local subdirs = dir:sub(#mediaDir + 1, #dir)
    local i, j = string.find(subdirs, '/')
    if not i then return subdirs end
    return subdirs:sub(0, i - 1)
end


local function check_initials()
    title = extract_title()
    curr_ep = get_ep()
    curr_list = JSON.loadTable(medialist)
    if curr_list[title] and curr_list[title] >= curr_ep then return end
end


--prevent nil errors on startup pause property change
local function file_load()
    if dir:sub(0, #mediaDir) ~= mediaDir then return end
    --refactor so it doesn't depend on outside variables
    check_initials()
    msg.info(curr_ep .. ":".. curr_list[title])
    mp.observe_property('pause', 'bool', handle_pause)
    mp.register_event('seek', handle_seek)
end

mp.register_event('file-loaded', file_load)
--mark previous completed
mp.add_forced_key_binding('ctrl+w', 'set_ep', function() complete_ep(curr_ep - 1) end)
--mark current completed
mp.add_forced_key_binding('ctrl+shift+w', 'set_ep', function() complete_ep(curr_ep) end)












