
is_mixtable_enable = true


function generate_secret_key()
	-- 生成密钥
end

if is_mixtable_enable then
	g_mixtable_secret_key = generate_secret_key()
end

-- 把解密和加密函数前置 因为后面的table sort的patch里会用到
local function encrypt(value)
	-- 对数值进行加密
end


local function decrypt(value)
	-- 对数值进行解密
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

    rawinsert = table.insert;
    function table.insert (table, pos, value)
        if table.__proxy then
            table[#table.__proxy+1] = value and value or pos
        else
        	local _ = value and ( rawinsert(table, pos, value) or true) or rawinsert(table, pos)
        end
    end

	rawremove = table.remove
	function table.remove(tbl, pos)
		local _ = tbl.__proxy and ( rawremove(tbl.__proxy, pos) or true) or rawremove(tbl, pos)
	end

	rawsort = table.sort
	function table.sort(tbl, cmpfunc)
		if tbl.__proxy then 
			local _cmpfunc = function (pre, nxt)
				local _pre = pre
				local _nxt = nxt
				if type(pre) == "number" then
					_pre = decrypt(pre)
				end

				if type(nxt) == "number" then
					_nxt = decrypt(nxt)
				end

				if cmpfunc then
					return cmpfunc(_pre, _nxt)
				else
					return _pre < _nxt
				end
			end

			rawsort(tbl.__proxy, _cmpfunc)
		else
			local _ = cmpfunc and ( rawsort(tbl, cmpfunc) or true) or rawsort(tbl)
		end
	end


	
end



--[[
	创建一个加密表

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
					return decrypt(_val) 
					
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
					if v.__proxy == nil then --非加密表才需要转换创建一个新表 加密表的赋值还是保持有索引
						local _ntbl = create_mix_table()
						for _k, _v in pairs(v) do
							_ntbl[_k] = _v
						end

						rawset(t.__proxy, k, _ntbl)
					else 
						rawset(t.__proxy, k, v)
					end
				else
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
深拷贝
]]
function deepcopy(value)
	local copy
	if type(value) == "table" then
		copy = {}
		for k,v in next, value, nil do
			copy[k] = deepcopy(v)
		end

	else
		copy = value
	end
	
	return copy 			
end


