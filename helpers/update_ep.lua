local utils = require('mp.utils')

--json read/write adopted from gist
-- read json file if exists
--      check folder where media is being played. grab ep and increment
-- otherwise create one
local media_list = os.getenv('HOME') .. '/.media_list.json'
local title = utils.getcwd():match( "([^/]+)$" )


-- JSON loading and saving
local list = {}
list.saveTable = function(path, v)
    local file = io.open(path, "w")
    local contents = utils.format_json(v)
    file:write(contents)
    io.close(file)
end

list.loadTable = function(path)
    local contents = ""
    local myTable = {}
    local file = io.open(path,"r")
    if file then
        local contents = file:read("*a")
        myTable = utils.parse_json(contents);
        io.close(file)
        return myTable
    end
    return nil
end


curr_list = list.loadTable(media_list)
-- 40149617/split-string-with-specified-delimiter-in-lua
function split(s, sep)
    local fields = {}
    
    local sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    -- changing such that it is a dictionary
    local i = 0
    string.gsub(s, pattern, function(c) fields[c] = i; i = i + 1 end)
    
    return fields
end

local function get_ep_order()
    local filename = mp.get_property('filename')
    local commands = {'find', utils.getcwd(), '-type', 'f', '-name', '*.mkv', '-printf', "%f\n"}
    local result = mp.command_native({
            name = 'subprocess',
            playback_only = false,
            capture_stdout = true,
            args = commands
        })
    if result.status == 0 then
        titles = split(result.stdout, '\n')
        return titles[filename] + 1
    end
    return 0
end



local handle_seek, handle_pause
local function complete_ep()
    mp.unobserve_property(handle_pause)
    mp.unregister_event(handle_seek)
    curr_list[title] = curr_list[title] and curr_list[title] + 1 or get_ep_order()
    list.saveTable(media_list, curr_list)
end

local timer
--increment and write to json when 85% passed or last chapter crossed
--courtsey of @gim-
local function start_timer()
    local threshold = mp.get_property('duration')
    local curr_time = mp.get_property('time-pos')
    threshold = threshold * 0.85 
    local until_threshold = threshold - curr_time
    if until_threshold > 0 then
        timer = mp.add_timeout(until_threshold, complete_ep)
    else
        complete_ep()
    end
    mp.msg.info(until_threshold)
end
handle_pause = function(_, paused)
    if paused and timer then
        timer:kill()
        timer = nil
        mp.msg.info('timer stopped')
    else
        start_timer()
    end
end

handle_seek = function()
    if timer then timer:kill(); timer = nil end
    start_timer()
end



--prevent nil errors on startup pause property change
local function file_load()
    mp.msg.info('file loaded')
    mp.observe_property('pause', 'bool', handle_pause)
    mp.register_event('seek', handle_seek)
end

mp.register_event('file-loaded', file_load)










