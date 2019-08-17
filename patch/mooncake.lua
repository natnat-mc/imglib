local MoonCake=require 'mooncake'
local http = require("http")
local https = require("https")
local path = require("path")
local fs = require('fs')
local mime = require('mooncake/libs/mime')
local helpers = require('mooncake/libs/helpers')
local querystring = require('querystring')
local JSON = require("JSON")
local Cookie = require("mooncake/libs/cookie")
require("mooncake/libs/ansicolors")

local getQueryFromUrl = function(url)
  local params = string.match(url, "?(.*)") or ""
  return querystring.parse(params)
end

function MoonCake:handleRequest(req, res)
    local url = req.url
    local method = string.lower(req.method)
    res.req = req
    local querys = getQueryFromUrl(url)
    req.query = querys
    req.start_time = helpers.getTime()
    res:on("finish", function()
        helpers.log(req, res)
    end)
    if req.headers.cookie then
        local cookie = Cookie:parse(req.headers.cookie)
        req.cookie = cookie or {}
    else
        req.cookie = {}
    end
    if method ~= "get" then
        local body = ""
        local fileData = ""
        req:on("data", function(chunk)
            if req.headers['Content-Type'] then
                if string.find(req.headers['Content-Type'], "multipart/form-data", 1, true) then
                    fileData = fileData..chunk
                else
                    body = body..chunk
                end
            else
                body = body..chunk
                if #body > 0 then
                    res:status(400):json({
                        status = "failed",
                        success = false,
                        code = 400,
                        message = "Request is not valid, 'Content-Type' should be specified in header if request body exist."
                    })
                end
            end
        end)
        req:on("end", function()

            local contentType = req.headers['Content-Type']
            if contentType and string.find(contentType, "multipart/form-data", 1, true) then
                local boundary = string.match(fileData, "^([^\r?\n?]+)\n?\r?")
                local fileArray = helpers.split2(fileData,boundary)
                table.remove(fileArray)
                table.remove(fileArray, 1)
                req.files = {}
                req.body = {}
                for _, fileString in pairs(fileArray) do
                    local header, headers = string.match(fileString, "^\r?\n(.-\r?\n\r?\n)"), {}
                    local content = ""
                    string.gsub(fileString, "^\r?\n(.-\r?\n\r?\n)(.*)", function(_,b)
                        if b:sub(#b-1):find("\r?\n") then
                            local _, n = b:sub(#b-1):find("\r?\n")
                            content = b:sub(0,#b-n)
                        end
                    end)
                    string.gsub(header, '%s?([^%:?%=?]+)%:?%s?%=?%"?([^%"?%;?%c?]+)%"?%;?%c?', function(k,v)
                        headers[k] = v
                    end)
                    if headers["filename"] then
                        local tempname = os.tmpname()
                        fs.writeFileSync(tempname, content)
                        req.files[headers["name"]] = {path = tempname, name = headers["filename"], ["Content-Type"] = headers["Content-Type"] }
                    else
                        req.body[headers["name"]] = content
                    end
                end
            else
                local bodyObj
                if contentType then
                    if req.headers["Content-Type"]:sub(1,16) == 'application/json' then
                        -- is this request JSON?
                      bodyObj = JSON.parse(body, 1, JSON.null)
                    elseif req.headers["Content-Type"]:sub(1, 33) == "application/x-www-form-urlencoded" then
                        -- normal form
                        bodyObj = querystring.parse(body)
                    else
                        -- content-type: text/xml
                        bodyObj = body
                    end
                else
                    if #body > 0 then
                        res:status(400):json({
                            status = "failed",
                            success = false,
                            code = 400,
                            message = "Bad Request, 'Content-Type' in request headers should be specified if request body exist."
                        })
                    end
                end
                req.body = bodyObj or {}
                if req.body._method then
                    req._method = req.body._method:lower()
                end
            end

            req.body = req.body or {}
            req.files = req.files or {}

            self:execute(req, res)
        end)
    else
        req.body = {}
        self:execute(req, res)
    end
end
