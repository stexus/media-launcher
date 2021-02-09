local utils = require('mp.utils')

--json read/write adopted from gist
-- read json file if exists
--      check folder where media is being played. grab ep and increment
-- otherwise create one
local medialist = os.getenv('HOME') .. '/.medialist.json'
local mediaDir = '/mnt/misc-ssd/Anime/'
local dir, title = utils.split_path(utils.getcwd())




-- JSON loading and saving
local list = {}
list.saveTable = function(path, v)
    local file = io.open(path, "w+")
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
        myTable = utils.parse_json(contents) or {}
        io.close(file)
    else
        list.saveTable(path)
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
local function get_ep_order()
    -- using mostly bash to be absolutely consistent with python script
    local filename = mp.get_property('filename')
    local commands = {'find', utils.getcwd(), '-type', 'f', '-name', '*.mkv', '-printf', "%f\n"}
    local result = subprocess(commands)
    local line
    if result.status == 0 then 
        local sorted = subprocess({'sort'}, result.stdout)
        mp.msg.info(sorted.stdout)
        line = subprocess({'grep', '-Fn', filename}, sorted.stdout)
    end
    if line.status == 0 then
        mp.msg.info(line.stdout)
        local end_index = line.stdout:find(':')
        local ep = line.stdout:sub(0, end_index - 1)
        return tonumber(ep)
    end
    return 0
end


local handle_seek, handle_pause, timer, curr_list
local function kill_timer()
    if timer then
        timer:kill()
        timer = nil
        mp.msg.info('timer stopped')
    end
end
local function killall()
    kill_timer()
    mp.unobserve_property(handle_pause)
    mp.unregister_event(handle_seek)
end

local function complete_ep()
    mp.msg.info('episode completed')
    killall()
    curr_list[title] = get_ep_order()
    list.saveTable(medialist, curr_list)
end

--increment and write to json when 85% passed or last chapter crossed
--courtsey of @gim-
local function start_timer()
    local threshold = mp.get_property('duration')
    local curr_time = mp.get_property('time-pos')
    threshold = threshold * 0.85 
    local until_threshold = math.max(threshold - curr_time, 0)
    timer = mp.add_timeout(until_threshold, complete_ep)
    mp.msg.info('time left: ' .. until_threshold)
end
handle_pause = function(_, paused)
    if paused then kill_timer()
    else start_timer() end
end

handle_seek = function()
    kill_timer()
    start_timer()
end



--prevent nil errors on startup pause property change
local function file_load()
    if mediaDir ~= dir then return end
    curr_list = list.loadTable(medialist)
    mp.observe_property('pause', 'bool', handle_pause)
    mp.register_event('seek', handle_seek)
end

mp.register_event('file-loaded', file_load)










