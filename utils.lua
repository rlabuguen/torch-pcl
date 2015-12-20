local ffi = require 'ffi'
local pcl = require 'pcl.PointTypes'

local utils = {}

local type_key_map = {}
type_key_map[pcl.PointXYZ] = 'XYZ'
type_key_map[pcl.PointXYZI] = 'XYZI'
type_key_map[pcl.PointXYZRGBA] = 'XYZRGBA'
type_key_map[pcl.PointNormal] = 'XYZNormal'
type_key_map[pcl.PointXYZINormal] = 'XYZINormal'
type_key_map[pcl.PointXYZRGBNormal] = 'XYZRGBNormal'
utils.type_key_map = type_key_map

function utils.create_typed_methods(prefix, names, type_key)
  local map = {}
  for i,n in ipairs(names) do
    local full_name = string.gsub(prefix .. n, 'TYPE_KEY', type_key)
    -- use pcall since not all types support all functions
    local ok,v = pcall(function() return pcl.lib[full_name] end)
    if ok then
      map[n] = v
    end
  end
  
  -- check whether we have new and delete functions
  -- automatically register objects created by new with the gc 
  local _new, _clone, _delete = map.new, map.clone, map.delete
  
  if _new and _delete then
    map.new = function(...)
      local obj = _new(...)
      ffi.gc(obj, _delete)
      return obj
    end
  end
  
  if _clone and _delete then
    map.clone = function(...)
      local obj = _clone(...)
      ffi.gc(obj, _delete)
      return obj
    end
  end
  
  return map
end

function utils.check_arg(argName, check, errorMsg)
  if not check then
    error("Invalid argument '" .. argName .. " ': " .. errorMsg)
  end
end

function utils.opt(t)
  return t and t:cdata() or ffi.NULL
end

local normal_type_map = {}
normal_type_map[pcl.PointXYZ] = pcl.PointNormal
normal_type_map[pcl.PointXYZI] = pcl.PointXYZINormal
normal_type_map[pcl.PointXYZRGBA] = pcl.PointXYZRGBNormal
utils.normal_type_map = normal_type_map

function utils.getNormalTypeFor(pointType)
  return utils.normal_type_map[pointType]
end

return utils