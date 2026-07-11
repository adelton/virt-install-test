
import "test-matrix-to-html-lib" as matrix_to_html;

def linebreaks:
	gsub(","; ",\u200b")
	| gsub("(?<c>[.=])"; "\u200b\(.c)")
;

flatten

| map(.["host-ubuntu"] = (
	if .["runs-on"] | startswith("ubuntu-26.04") then "26.04"
	elif .["runs-on"] | startswith("ubuntu-24.04") then "24.04"
	else .["runs-on"]
	end
	)
	|
	.["runs-on"] = (
	if .["runs-on"] | endswith("-arm") then "aarch64"
	else "x86_64"
	end
	)
	|
	.boot = (
	if (.boot // "") != "" then "--boot " + .boot
	else (.args // "") | (match("--boot[ =][^ ]+") | .string) // null
	end
	)
)

| sort_by(.["host-ubuntu"], .boot, .network, .["secure-boot-check"], .["second-machine"])

# raw hash of hashes with display string for combinations we will run
| reduce .[] as $r ({};
	.[ $r["host-ubuntu"] ]
	[ if ($r.boot // "") != "" then $r.boot else "(no --boot)" end + "\n<br/>\u2014\u2014<br/>\n" + $r.network | linebreaks ]
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
	[ "Host Ubuntu", "Boot \n<br/>\u2014\u2014<br/>\n network", "Secure Boot", "Second machine" ]
)

