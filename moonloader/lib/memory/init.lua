-- Minimal memory module stub for mimgui compatibility
-- Provides memory.fill function using FFI

local ffi = require 'ffi'

local M = {}

-- Fill memory with a byte value
function M.fill(address, value, size, protect)
    -- Use FFI to write memory directly
    local ptr = ffi.cast('void*', address)
    local byte_arr = ffi.cast('uint8_t*', ptr)
    for i = 0, size - 1 do
        byte_arr[i] = value
    end
    return true
end

-- Read memory
function M.read(address, size)
    local ptr = ffi.cast('const uint8_t*', address)
    local result = {}
    for i = 0, size - 1 do
        table.insert(result, ptr[i])
    end
    return table.concat(result)
end

-- Write memory
function M.write(address, data)
    local ptr = ffi.cast('uint8_t*', address)
    for i = 1, #data do
        ptr[i - 1] = data:byte(i)
    end
    return true
end

-- Get memory protection (stub)
function M.getprotect(address)
    return 0x40 -- PAGE_EXECUTE_READWRITE
end

-- Set memory protection (stub)
function M.setprotect(address, size, protect)
    return true
end

-- Allocate memory (stub)
function M.alloc(size)
    return 0
end

-- Free memory (stub)
function M.free(address)
    return true
end

return M
