local utils = require('mp.utils')
local msg = require('mp.msg')
local medialist = os.getenv('HOME') .. '/.medialist.json'

--allow for soft links
local mediadir_name = 'Anime'

--only before init() is run. otherwise set to 'root' media directory
local dir = utils.getcwd()

-- create curr.ep object
local curr = {}
curr.ep = -1
curr.id = -1
curr.title = nil
curr.list = nil

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
Timer.on_seek = function()
    if not Timer.instance then return end
    Timer.kill()
    Timer.start()
end

Timer.on_pause = function(_, paused)
    if paused then Timer.kill()
    else Timer.start() end
end

Timer.nuke = function()
    Timer.kill()
    mp.unobserve_property(Timer.on_pause)
    mp.unregister_event(Timer.on_seek)
end

--may have no parameter, so ep is null. defaults to curr.ep
Timer.complete = function(ep)
    msg.info('episode completed')
    Timer.nuke()
    curr.list[curr.title] = ep or curr.ep
    JSON.saveTable(medialist, curr.list)
    --send api request to anilist
    if curr.id > 0 then
        --send request
        msg.info('sending request to anilist')
    end
    mp.osd_message('Marked completed: '..curr.list[curr.title], 1)
end

Timer.start = function()
    local threshold = mp.get_property('duration')
    local time_pos = mp.get_property('time-pos')
    threshold = threshold * 0.85
    local until_threshold = math.max(threshold - time_pos, 0)
    Timer.instance = mp.add_timeout(until_threshold, function() Timer.complete(curr.ep) end)
    msg.info('time left: ' .. until_threshold)
end

Timer.kill = function()
    if Timer.instance then
        Timer.instance:kill()
        Timer.instance = nil
        msg.info('timer stopped')
    end
end

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
    local commands = {'find', dir..curr.title, '-type', 'l,f', '-name', '*.mkv'}
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
    local anilist_entries = curr.list['anilist']
    local id = -1
    if not anilist_entries then return id end
    --msg.info(dump(anilist_entries))
    for _, entry in ipairs(anilist_entries[curr.title]) do
        --msg.info(dump(entry))
        --msg.info(curr.ep)
        if entry_ep(entry) <= curr.ep then
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
    curr.id = id
    if not curr.list['anilist'] then curr.list['anilist'] = {} end
    local anilist_entries = curr.list['anilist']
    if not anilist_entries[curr.title] then
        anilist_entries[curr.title] = {}
    end
    local new_entry = {curr.ep, tonumber(id)}
    for i, entry in ipairs(anilist_entries[curr.title]) do
        if entry_ep(entry) == curr.ep then
            anilist_entries[curr.title][i] = new_entry
            return
        end
    end
    table.insert(anilist_entries[curr.title], new_entry)
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



--startup
local function init()
    local i, j = string.find(dir, mediadir_name)
    --autoload compatibility
    if curr.title == nil then
        curr.title = extract_title(dir:sub(j+2, #dir))
        dir = dir:sub(0, j+1)
    end
    curr.ep = get_ep()
    curr.list = JSON.loadTable(medialist)
    curr.id = extract_id()
    --set variable to update in anilist
end

local function file_load()
    Timer.nuke()
    if string.match(dir, mediadir_name) == nil then return end
    init()
    msg.info('directory: '..dir..' | title: ' .. curr.title .. ' | current_ep: ' .. curr.ep)
    if curr.list[curr.title] and curr.list[curr.title] >= curr.ep then return end
    mp.observe_property('pause', 'bool', Timer.on_pause)
    mp.register_event('seek', Timer.on_seek)
end

----mpv handlers
mp.register_event('file-loaded', file_load)
--mark previous completed
mp.add_forced_key_binding('ctrl+shift+w', 'set_ep_prev', function()
    Timer.complete(curr.ep - 1)
    mp.observe_property('pause', 'bool', Timer.on_pause)
    mp.register_event('seek', Timer.on_seek)
end)

--mark current completed
mp.add_forced_key_binding('ctrl+w', 'set_ep_Surr', function() Timer.complete(curr.ep) end)
mp.add_forced_key_binding('alt+a', 'rofi-blocks', rofi_selection)
