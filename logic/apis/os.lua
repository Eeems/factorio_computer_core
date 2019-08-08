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
                if not time then
                    -- We'll assume that the game started at the begining of "time"
                    -- (Wednesday, January 1, 3000 12:00:00 AM)
                    time = {32503680000 + math.floor(self.__getPlayedTick() / 60)}
                end
                year = math.floor((ts / 31557600) + 1970)
                time = time - (year - 1970) * 31557600
                return self.__date(format, time)
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
                if not self.__fileExist(filepath) then
                    return nil, "The file does not exist"
                end
                self.__removeFile(filepath)
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
                self.__writeFile(newname, self.__readFle(oldname))
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
            function(self, table)
                if not table then
                    return 32503680000 + math.floor(self.__getPlayedTick() / 60)
                end
                year = table.year
                time = 0
                for y in self.__range(1970, year - 1) do
                    time = time + 31557600
                    if y%4 == 0 and (y%100 ~= 0 or y%400 == 0) then
                        time = time + 86400
                    end
                end
                if table.month > 0 then
                    isLeapYear = year%4 == 0 and (year%100 ~= 0 or year%400 == 0)
                    for month in self.__range(1, month - 1) do
                        if month == 2 and isLeapYear then
                            time = time + 29 * 86400
                        elseif month == 2 then
                            time = time + 28 * 86400
                        elseif month % 2 == 0 then
                            time = time + 30 * 86400
                        else
                            time = time + 31 * 86400
                        end
                    end
                end
                time = time + table.day * 86400
                if table.hour ~= nil then
                    time = time + table.hour * 3600
                else
                    time = time + 12 * 3600
                end
                if table.minute ~= nil then
                    time = time + table.minute * 60
                end
                if table.sec ~= nil then
                    time = time + table.sec
                end
                return time
            end
        },
        tmpname = {
            "os.tmpname() - Returns a string with a file name that can be used for a temporary file. The file must be explicitly opened before use and explicitly removed when no longer needed",
            function(self)
                return "/tmp/" + self.__getGameTick() + math.random(0,100)
            end
        }
    }
})
