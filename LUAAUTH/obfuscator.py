import sys
import base64
import zlib

def obfuscate_lua(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        code = f.read()
    
    compressed = zlib.compress(code.encode('utf-8'))
    b64 = base64.b64encode(compressed).decode('utf-8')

    obfuscated_code = f"""
-- Ketamine Hub Obfuscated
local base64="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function dec(data)
    local B=base64:gsub('',''):split('')
    local t={{}} for i=1,64 do t[B[i]]=i-1 end
    data=data:gsub('[^'..base64..'=]','')
    local dec=data:gsub('.',function(x) if x=='=' then return '' end
    local r,b='',t[x] for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
    return r end)
    local out='' for i=1,#dec,8 do
        local b=dec:sub(i,i+7)
        if #b==8 then out=out..string.char(tonumber(b,2)) end
    end
    return out
end

-- Fallback decompression or we can just load the raw code if we don't compress. 
-- Wait, Roblox doesn't have a built-in zlib decompress for Lua easily accessible in all executors unless we use lz4/syn.crypt.
"""

    # Actually, zlib in raw Lua is hard. Let's just do base64 and string.byte obfuscation for simplicity.
    bytes_array = "\\".join([str(b) for b in code.encode('utf-8')])
    byte_str = "\\".join([str(x) for x in code.encode('utf-8')])
    
    # Better string.byte approach:
    hex_str = ''.join([f'\\x{b:02x}' for b in code.encode('utf-8')])
    
    simple_obf = f"""-- Ketamine Hub Auth Loader (Obfuscated)
local s = "{hex_str}"
local f, err = loadstring(s)
if f then f() else warn("Error loading script", err) end
"""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(simple_obf)
    
    print(f"Obfuscated {input_file} to {output_file}")

if __name__ == '__main__':
    obfuscate_lua(sys.argv[1], sys.argv[2])
