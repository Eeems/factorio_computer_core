require("logic.computer")

table.insert(computer.apis,{
    name = "os",
    description = "The Operating System API allows for interfacing with the Lua based Operating System itself.",
    entities = nil,
    events = {
        on_tick = function(self, event)
            if not self._callbacks then self._callbacks = {} end

            for index, item in pairs(self._callbacks) do
                if item.type == "wait" and event.tick >= item.time then
                    self._callbacks[index] = nil
                    local fct, err = load(item.callback, nil, "bt", self.__env)
                    if err then
                        return self.__getAPI('term').write(err)
                    end
                    local success, result = pcall(fct, unpack(item.args or {}))
                    if not success then
                        return self.__getAPI('term').write(result)
                    end
                end
            end
        end
    },
    prototype = {
        __init = {
            "os.__init() - Init API",
            function(self)
                self._callbacks = {}
                self._env = {}
            end
        },
        getComputerID = {
            "os.getComputerID() - Returns the uniq ID of this computer",
            function(self)
                return self.__getID()
            end
        },
        getComputerLabel = {
            "os.getComputerLabel() - Returns the label of this computer",
            function(self)
                return self.__getLabel()
            end
        },
        setComputerLabel = {
            "os.setComputerLabel(label) - Set the label of this computer",
            function(self, label)
                self.__setLabel(label)
            end
        },
        setenv = {
            "os.setenv(varname, ...args) - Sets environment variables for the given name",
            function(self, varname, ...)
                self._env[varname] = {...}
            end
        },
        remenv = {
            "os.remenv(varname) - Remove environment variables for the given name",
            function(self, varname)
                self._env[varname] = nil
            end
        },
        pcall = {
            "os.pcall(callback, ...) - The os.pcall function calls its first argument in protected mode, so that it catches any errors while the function is running. If there are no errors, pcall returns true, plus any values returned by the call. Otherwise, it returns false, plus the error message.",
            function(self, callback, ...)
                if callback == nil then
                    return false, 'callback is nil'
                end
                local fct, err = load(string.dump(callback), nil, "b", self.__env)
                if err then
                    return false, err
                end
                return pcall(fct, ...)
            end
        },
        wait = {
            "os.wait(callback, seconds, ...args) - Wait a number of seconds before executing callback function",
            function(self, callback, seconds, ...)
                table.insert(self._callbacks, {
                    type = "wait",
                    time = self.__getGameTick() + seconds * 60,
                    callback = string.dump(callback),
                    args = {...}
                })
            end
        },
        require = {
            "os.require(filepath) - load and run library file",
            function(self, filepath)
                assert(type(filepath) == "string", "'os.require' require a filepath")
                assert(filepath ~= ".", "Unable to require directory '.'")
                assert(filepath ~= "..", "Unable to require directory '..'")

                return self.__require(filepath)
            end
        },
        -- Lua os module
        clock = {
            "os.clock() - return an approximation of the amount of in game seconds of CPU time used by the program",
            function(self)
                return math.floor(self.__getPlayedTick() / 60)
            end
        },
        date = {
            "os.date([format [, time]]) - Returns the current in-game date",
            function(self, format, time)
                if time == nil then
                    -- We'll assume that the game started at the begining of "time"
                    -- (Wednesday, January 1, 3000 12:00:00 AM)
                    time = 32503680000 + math.floor(self.__getPlayedTick() / 60)
                end
                if format == nil then
                    format = '%c'
                end
                if format == "*t" then
                    return self.__date(time)
                end
                return self.__strtime(format, time)
            end
        },
        difftime = {
            "os.difftime(t2, t1) - Returns the number of seconds from time t1 to time t2",
            function(self, t2, t1)
                return math.floor(t2 - t1)
            end
        },
        execute = {
            "os.execute([command]) - Run a system command and return the result",
            function(self, command)
                -- TODO: Handle executing another file and returning the result
                return nil
            end
        },
        exit = {
            "os.exit([code [, close]]) - Exits the running program",
            function(self, code, close)
                -- TODO: handle somehow
            end
        },
        getenv = {
            "os.getenv(varname) - Returns environment variables of the given name",
            function(self, varname)
                return unpack(self._env[varname] or {})
            end
        },
        remove = {
            "os.remove(filename) - Deletes a file with a given name. If this function fails it returns nil plus a string describing the error",
            function(self, filename)
                if not self.__fileExist(filename) then
                    return nil, "The file does not exist"
                end
                self.__removeFile(filename)
                return true, ""
            end
        },
        rename = {
            "os.rename(oldname, newname) - Renames a file named oldname to newname. If the function fails, it returns nil plus a string describing the error",
            function(self, oldname, newname)
                if not self.__fileExist(oldname) then
                    return nil, "old file does not exist"
                end
                if self.__fileExist(newname) then
                    return nil, "new file already exists"
                end
                self.__writeFile(newname, self.__readFile(oldname))
                self.__removeFile(oldname)
                return true, ""
            end
        },
        setlocale = {
            "os.setlocale(locale [, category]) - Sets the current locale of the program",
            function(locale, category)
                if not locale or locale == "c" or locale == "" then
                    return "c"
                end
                return nil
            end
        },
        time = {
            "os.time([table]) - Returns the current time when called without arguments. Or a time represented by the date and time specified in a given table",
            function(self, data)
                if not data then
                    return 32503680000 + math.floor(self.__getPlayedTick() / 60)
                end
                return self.__time(data)
            end
        },
        tmpname = {
            "os.tmpname() - Returns a string with a file name that can be used for a temporary file. The file must be explicitly opened before use and explicitly removed when no longer needed",
            function(self)
                return "/tmp/" .. self.__getGameTick() .. math.random(0,100)
            end
        }
    }
})
