
import "test-matrix-to-html-lib" as matrix_to_html;

def linebreaks:
	gsub(","; ",\u200b")
	| gsub("(?<c>[.=])"; "\u200b\(.c)")
;

flatten

| sort_by(.boot, .network, .["secure-boot-check"], .["second-machine"])

| [ .[] | .["runs-on"] = (
	if .["runs-on"] == "ubuntu-24.04" then "x86_64"
	elif .["runs-on"] == "ubuntu-24.04-arm" then "aarch64"
	else "?"
	end
)
]

# raw hash of hashes with display string for combinations we will run
| reduce .[] as $r ({}; .[ $r.boot + "<br/>" + $r.network | linebreaks ]
	[ $r["secure-boot-check"] // "(not checked)" | linebreaks ]
	[ $r.["second-machine"] // "(none)" ][ $r.name ][ $r.osinfo ]
	[ $r["arch-display"][0:1]
		+ ( if $r.arch == null or $r.arch == "" then "?"
			elif $r["arch-display"] != $r.arch then $r.arch[0:1]
			else "" end )
		+ "\u200b@\u200b" + $r["runs-on"][0:1] ] = "🔷")
| . as $data

| matrix_to_html::table(
	"Image / osinfo / arch @ host arch";
	[ "Boot / network", "Secure Boot", "Second machine" ]
)

