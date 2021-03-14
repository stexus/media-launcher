local utils = require('mp.utils')
local msg = require('mp.msg')

--separate json object with explicitly defined names
--JSON read/write adopted from gist
-- read JSON file if exists
--      check folder where media is being played. grab ep and increment
-- otherwise create one
-- create curr_ep object
local curr = {}
local curr_list, title, curr_ep, curr_id
--local medialist = os.getenv('HOME') .. '/.medialist.json'
local medialist = '/mnt/misc-ssd/Coding/Projects/media-tracker/medialist.json'

--allow for soft links
local mediadir_name = 'Anime'

--only before init() is run. otherwise set to 'root' media directory
local dir = utils.getcwd()


--processing functions--
local function subprocess(command, stdout, stdin)
    if stdout == nil then
        stdout = true
    end
    return mp.command_native({
            name = 'subprocess',
            playback_only = false,
            capture_stdout = stdout,
            stdin_data = stdin,
            args = command
        })
end

local function get_ep()
    -- using mostly bash to be absolutely consistent with python script
    local filename = mp.get_property('filename')
    local commands = {'find', dir..title, '-type', 'l,f', '-name', '*.mkv'}
    local result = subprocess(commands)
    local line
    if result.status == 0 then
        --changed to named arguments
        local sorted = subprocess({'sort'}, true, result.stdout)
        line = subprocess({'grep', '-Fn', filename}, true, sorted.stdout)
    end
    if line.status == 0 then
        local end_index = line.stdout:find(':')
        local ep = line.stdout:sub(0, end_index - 1)
        return tonumber(ep)
    end
    return 0
end

--for debugging
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
local function entry_ep(entry) return entry[1] end
local function entry_id(entry) return entry[2] end
local function extract_id()
    local anilist_entries = curr_list['anilist']
    local id = -1
    --msg.info(dump(anilist_entries))
    for _, entry in ipairs(anilist_entries[title]) do
        --msg.info(dump(entry))
        --msg.info(curr_ep)
        if entry_ep(entry) <= curr_ep then
            id = entry_id(entry)
        end
    end
    --msg.info(entry_id)
    return id
end

local function extract_title(subdirs)
    local i, j = string.find(subdirs, '/')
    if not i then return subdirs end
    mp.osd_message(subdirs:sub(i + 1, #subdirs), 2)
    return subdirs:sub(0, i - 1)
end

local function add_anilist_entry(id)
    curr_id = id
    if not curr_list['anilist'] then curr_list['anilist'] = {} end
    local anilist_entries = curr_list['anilist']
    if not anilist_entries[title] then
        anilist_entries[title] = {}
    end
    local new_entry = {curr_ep, tonumber(id)}
    for i, entry in ipairs(anilist_entries[title]) do
        if entry_ep(entry) == curr_ep then
            anilist_entries[title][i] = new_entry
            return
        end
    end
    table.insert(anilist_entries[title], new_entry)
    --msg.info(dump(anilist_entries))
end



local function rofi_selection()
    local tmp_name = os.tmpname()
    subprocess({'selector', tmp_name}, true, '')
    local tmp = io.open(tmp_name, 'r')
    if tmp then
        local id = tmp:read('*a')
        io.close(tmp)
        os.remove(tmp_name)
        add_anilist_entry(tonumber(id))
    end
end


------------------------------------------------------------------


-- JSON loading and saving
local JSON = {}
JSON.saveTable = function(path, v)
    local file = io.open(path, "w+")
    local contents = utils.format_json(v)
    file:write(contents)
    io.close(file)
end

JSON.loadTable = function(path)
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

-- Timer object
local Timer = {}

-- handlers
local function handle_seek()
    if not Timer.instance then return end
    Timer.kill()
    Timer.start()
end
local function handle_pause(_, paused)
    if paused then Timer.kill()
    else Timer.start() end
end

local function killall()
    Timer.kill()
    mp.unobserve_property(handle_pause)
    mp.unregister_event(handle_seek)
end

--may have no parameter, so ep is null. defaults to curr_ep
local function complete_ep(ep)
    msg.info('episode completed')
    killall()
    curr_list[title] = ep or curr_ep
    JSON.saveTable(medialist, curr_list)
    --send api request to anilist
    if curr_id > 0 then
        --send request
        msg.info('sending request to anilist')
    end
    mp.osd_message('Marked completed: '..curr_list[title], 1)
end
-------------------------

Timer.start = function()
    local threshold = mp.get_property('duration')
    local curr_time = mp.get_property('time-pos')
    threshold = threshold * 0.85 
    local until_threshold = math.max(threshold - curr_time, 0)
    Timer.instance = mp.add_timeout(until_threshold, function() complete_ep(curr_ep) end)
    msg.info('time left: ' .. until_threshold)
end

Timer.kill = function()
    if Timer.instance then
        Timer.instance:kill()
        Timer.instance = nil
        msg.info('timer stopped')
    end
end




--startup

local function init()
    local i, j = string.find(dir, mediadir_name)
    if title == nil then
        title = extract_title(dir:sub(j+2, #dir))
        dir = dir:sub(0, j+1)
    end
    curr_ep = get_ep()
    curr_list = JSON.loadTable(medialist)
    curr_id = extract_id()
    --set variable to update in anilist
end

local function file_load()
    killall()
    if string.match(dir, mediadir_name) == nil then return end
    init()
    msg.info('directory: '..dir..' | title: ' .. title .. ' | current_ep: ' .. curr_ep)
    if curr_list[title] and curr_list[title] >= curr_ep then return end
    mp.observe_property('pause', 'bool', handle_pause)
    mp.register_event('seek', handle_seek)
end

mp.register_event('file-loaded', file_load)
--mark previous completed
mp.add_forced_key_binding('ctrl+w', 'set_ep_prev', function() 
    complete_ep(curr_ep - 1)
    mp.observe_property('pause', 'bool', handle_pause)
    mp.register_event('seek', handle_seek)
end)

--mark current completed
mp.add_forced_key_binding('ctrl+shift+w', 'set_ep_Surr', function() complete_ep(curr_ep) end)
mp.add_forced_key_binding('alt+a', 'rofi-blocks', rofi_selection)



