def th($rowspan; $colspan):
	"      " + "<th"
		+ (if $rowspan > 1 then " rowspan=\"" + ($rowspan | tostring) + "\"" else "" end)
		+ (if $colspan > 1 then " colspan=\"" + ($colspan | tostring) + "\"" else "" end)
		+ ">"
		+ .
		+ "</th>"
;

def td($rowspan):
	"      " + "<td"
		+ (if $rowspan > 1 then " rowspan=\"" + ($rowspan | tostring) + "\"" else "" end)
		+ ">"
		+ .
		+ "</td>"
;

def linebreaks:
	gsub(","; ",\u200b")
	| gsub("(?<c>[.=])"; "\u200b\(.c)")
;

3 as $ncolstart

| flatten

| [ .[] | .["runs-on"] = (
	if .["runs-on"] == "ubuntu-24.04" then "x86_64"
	elif .["runs-on"] == "ubuntu-24.04-arm" then "aarch64"
	else "?"
	end
)
| .arch = ( if .arch == null then "default" else .arch[0:1] end )
]

# raw hash of hashes with display string for combinations we will run
| reduce .[] as $r ({}; .[ $r.boot | linebreaks ][ $r["secure-boot-check"] // "(not checked)" | linebreaks ]
	[ $r.["second-machine"] // "(none)" ][ $r.name ][ $r.osinfo ][ $r.arch + "@" + $r["runs-on"][0:1] ] = "🔷")
| . as $data

# set the top data (the rows in the table) as sorted to_entries
| [ paths | select(length < $ncolstart) ] + [[]] | sort_by(-length)
| reduce .[] as $p ($data; getpath($p) |= (to_entries | sort_by(.key) | map(.depth = ($p | length))))
| . as $data

# use multiplication to retrieve combinations that will define the columns
| [ paths(type == "object") | select(length == $ncolstart * 2) ]
| reduce .[] as $p ({}; . * ($data | getpath($p)))

# turn the colum headers into sorted to_entries
| walk(if type == "object" then to_entries | sort_by(.key) else . end)
| . as $columns
# add the .depth for columns
| ( reduce (paths(type == "object")) as $p ($columns; setpath($p + [ "depth" ]; ($p | length - 1) / 2)) ) as $columns
# and store the maximal depth
| ( [ $columns | .. | .depth? ] | max) as $maxdepth

|

"<table>",
"  <thead>",

"    <tr>",
( "Boot" | th($ncolstart + 1; 1) ),
( "Secure Boot" | th($ncolstart + 1; 1) ),
( "Second machine" | th($ncolstart + 1; 1) ),
( "Image / osinfo / arch @ host arch" | th(1; [ $columns | .. | select(.depth? == $maxdepth) ] | length ) ),
"    </tr>",

(
range($maxdepth + 1) as $r
|
"    <tr>",
( $columns | .. | select(.depth? == $r) | . as $e | .key | th(1; [ $e | .. | select(.depth? == $maxdepth) ] | length) ),
"    </tr>"
),

"  </thead>",
"  <tbody>",

(
$data
| [ paths(objects) | select(length < $ncolstart * 2) ]
| foreach .[] as $p([null, [0]];
	. = [.[1], $p];
	( .[1] as $p | $data | getpath($p) ) as $v
	|
	if (.[0] | length) >= (.[1] | length) then "    <tr>" else empty end,
	( $v | .key | th([ $v | .value | .. | arrays | .[] | select(.depth? == $ncolstart - 1)] | length; 1)),
	if (.[1] | length) == $ncolstart * 2 - 1 then
		( $columns | paths(.depth? == $maxdepth) as $p
			| [ range(1; 2 * $maxdepth + 2; 2) | $p[0: .] + ["key"] ] as $p
			| [ $columns | getpath($p[]) ] as $p
			| $v
			| getpath(["value"] + $p) | td(1)),
		"    </tr>"
	else empty end
	)
)
,

"  </tbody>",
"</table>"
