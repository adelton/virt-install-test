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

flatten
| . as $data
| reduce .[] as $r ({}; .[ $r.name ][ $r.osinfo ] = 1)
| with_entries( .value = ( .value | keys | sort ) )
| . as $dist
| $data
| reduce .[] as $r ({}; .[ $r.boot + " / " + ($r["secure-boot-check"] // "(not checked)") ][ $r.["second-machine"] // "(none)" ][ $r.name ][ $r.osinfo ]  = "🔷")
| . as $data
|

"<table>",
"  <thead>",

"    <tr>",
( "Boot / Secure Boot" | th(3; 1) ),
( "Second machine" | th(3; 1) ),
( "Image" | th(1; [ $dist | to_entries | .[] | .value | length ] | add ) ),
"    </tr>",
"    <tr>",
( $dist | keys | sort | .[] | th(1; $dist[.] | length) ),
"    </tr>",
"    <tr>",
( $dist | keys | sort | .[] | $dist[.][] | th(1; 1) ),
"    </tr>",

"  </thead>",
"  <tbody>",

( $data | to_entries | sort_by(.key) | .[]
	| .key as $k
	| .value | to_entries | sort_by(.key)
	| . as $v
	| ( "    <tr>",
		( $k | th( $v | length; 1) ),
			( $v | .[0].key as $first_key | .[] | .value as $v
				| ( if .key != $first_key then "    <tr>" else empty end ),
				( .key | th(1; 1),
					( $dist | to_entries | .[] | .key as $k | .value[]
						| [ $k, . ] as $p | $v | getpath($p) | td(1))
				),
				"    </tr>"
			)
		)
	),

"  </tbody>",
"</table>"
