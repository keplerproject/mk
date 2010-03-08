#!/usr/bin/env wsapi.cgi

local mk = require "mk"
local response = require "wsapi.response"
local cosmo = require "cosmo"

local songs = mk.new()

function songs.index(wsapi_env)
   local songlist = {
      "Sgt. Pepper's Lonely Hearts Club Band",
      "With a Little Help from My Friends",
      "Lucy in the Sky with Diamonds",
      "Getting Better",
      "Fixing a Hole",
      "She's Leaving Home",
      "Being for the Benefit of Mr. Kite!",
      "Within You Without You",
      "When I'm Sixty-Four",
      "Lovely Rita",
      "Good Morning Good Morning",
      "Sgt. Pepper's Lonely Hearts Club Band (Reprise)",
      "A Day in the Life"
   }
   local res = response.new()
   res:write(songs.layout(songs.render_index({ songs = songlist })))
   return res:finish()
end

songs:dispatch_get("index", "/", songs.index)

function songs.layout(inner_html)
  return string.format([[
      <html>
        <head><title>Song List</title></head>
        <body>%s</body>
      </html>
    ]], inner_html)
end

songs.render_index = cosmo.compile[[
	 <h1>Songs</h1>
	    <table>
	    $songs[=[<tr><td>$it</td></tr>]=]
	 </table>  
      ]]

return songs.run
