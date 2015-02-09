
is_mixtable_enable = true


function generate_secret_key()
	-- body
	math.randomseed(os.time())
	math.random()
	local r = math.random(30)
	return 2 ^ 16 +  2 ^ r - 1
end

if is_mixtable_enable then
	rawnext = next
	function next(t,k)
		local m = getmetatable(t)
		local n = m and m.__next or rawnext
		return n(t,k)
	end

	rawpairs = pairs
	function pairs(t) return next, t, nil end

	rawipairs = ipairs
	local function _ipairs(t, var)
		var = var + 1
		local value = t[var]
		if value == nil then return end
		return var, value
		end
	function ipairs(t) return _ipairs, t, 0 end

	g_mixtable_secret_key = generate_secret_key()
end





local function encrypt(value)
	return bit.bxor(value, g_mixtable_secret_key)
end


local function decrypt(value)
	return bit.bxor(value, g_mixtable_secret_key)
end



--[[
 


 
]]-- 
function create_mix_table()

	if is_mixtable_enable ~= true then
		return {}
	end

	local ctbl = { __index = ctbl, __proxy = {} }
	setmetatable(ctbl, {

		__index = function(t, k)
			local _val = rawget(t.__proxy, k)
			if _val ~= nil then
				if type(_val) == "number" then
					return decrypt(_val) --解密但是不支持非整数
				-- elseif type(_val) == "table" then
				-- 	return _val
					
				end
			end

			return _val
		end,

		__newindex = function (t, k, v)

			if v ~= nil then
				if type(v) == "number" then
					local _val = encrypt(v)
					if nil ~= _val then
						rawset(t.__proxy, k, _val)
					end
				elseif type(v) == "table" then
					local _ntbl = create_mix_table()
					for _k, _v in pairs(v) do
						_ntbl[_k] = _v
					end

					rawset(t.__proxy, k, _ntbl)
				else --其他的情况
					rawset(t.__proxy, k, v)
				end
			end      			
		end,

		__next = function(t, k)
			local _nextkey, _nextval = next(t.__proxy, k)
			if _nextkey ~= nil then
				_nextval = t[_nextkey]
			end
			return _nextkey, _nextval
		end		

	})

	return ctbl
end




--[[
	把amf3生成lua结构表里的冗余信息剔除 还原成真正的lua的table嵌套结构
]]
function trim_amf3_table(tbl)
	if tbl == nil then return end

	for k,v in pairs(tbl) do
		if k == "_class" then
			tbl[k] = nil
		end

		if type(v) == "table" then 
			if k ~= "_data" then
				trim_amf3_table(v)
			else
				trim_amf3_table(v)
				if #v > 0 then
					table.insert(tbl, v)
				end
				tbl[k] = nil
			end
		end
	end
end


--[[
把lua的table 深拷贝为mixtable
]]
function deepcopy_to_mix(secret_key, value)
	local copy
	if type(value) == "table" then
		copy = create_mix_table(secret_key)
		for k,v in next, value, nil do
			copy[k] = deepcopy_to_mix(secret_key, v)
		end
	else
		copy = value
	end
	
	return copy 	
end

--[[ 
把加密的mixtable 深拷贝为lua的原始table
]]
function deepcopy_to_lua(mvalue)
	local copy
	if type(mvalue) == "table" then
		copy = {}
		for k,v in next, mvalue, nil do
			copy[k] = deepcopy_to_lua(v)
		end

	else
		copy = mvalue
	end
	
	return copy 			
end
