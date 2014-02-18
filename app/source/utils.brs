' This Source Code Form is subject to the terms of the Mozilla Public
' License, v. 2.0. If a copy of the MPL was not distributed with this file,
' You can obtain one at http://mozilla.org/MPL/2.0/.

function fileExists(file as String) as integer
    fs = createObject("roFileSystem")
    if fs.exists(file) then
        return 1
    end if
    return 0
end function

' Registry helper functions. The registry is the only form of permanent storage
' Notes: http://sdkdocs.roku.com/display/sdkdoc/roRegistry

function registryRead(key, section = invalid)
    if section = invalid then section = "Default"
    sec = createObject("roRegistrySection", section)
    if sec.exists(key) then return sec.read(key)
    return invalid
end function

function registryWrite(key, val, section = invalid)
    if section = invalid then section = "Default"
    sec = createObject("roRegistrySection", section)
    sec.write(key, val)
    sec.flush()
end function

function registryDelete(key, section = invalid)
    if section = invalid then section = "Default"
    sec = createObject("roRegistrySection", section)
    sec.delete(key)
    sec.flush()
end function

' Convert associative array (hash) to a JSON string
' Borrowed from http://forums.roku.com/viewtopic.php?p=200229

function toJSON(array as object) as string
    if type(array) = "roArray" then
        return arrayToJSON(array)
    else if type(array) = "roAssociativeArray" then
        return associativeArrayToJSON(array)
    end if
    return invalid
end function

function associativeArrayToJSON(array as object) as string
    output = "{"
   
    for each key in array
        output = output + chr(34) + key + chr(34) + ": "
        value = array[key]
        if type(value) = "roString" or type(value) = "String" then
            output = output + chr(34) + value + chr(34)
        else if type(value) = "roInt" Or type(value) = "roFloat" then
            output = output + value.ToStr()
        else if type(value) = "roBoolean" then
            output = output + iif( value, "true", "false" )
        else if type(value) = "roArray" then
            output = output + arrayToJSON(value)
        else if type(value) = "roAssociativeArray" then
            output = output + associativeArrayToJSON(value)
        end if
        output = output + ","
    next
    if right(output, 1) = "," then
        output = left(output, len(output) - 1)
    end if
   
    output = output + "}"
    return output
end function

function arrayToJSON(array as object) as string
    output = "["
   
    for each value in array
        if type(value) = "roString" or type(value) = "String" then
            output = output + chr(34) + value + chr(34)
        else if type(value) = "roInt" Or type(value) = "roFloat" then
            output = output + value.toStr()
        else if type(value) = "roBoolean" then
            output = output + iif(value, "true", "false")
        else if type(value) = "roArray" then
            output = output + arrayToJSON(value)
        else if type(value) = "roAssociativeArray" then
            output = output + associativeArrayToJSON(value)
        end if
        output = output + ","
    next
    if right(output, 1) = "," then
        output = left(output, len(output) - 1)
    end if
   
    output = output + "]"
    return output
end function

function iif(condition, result1, result2)
    if condition then
        return result1
    else
        return result2
    end if
end function
