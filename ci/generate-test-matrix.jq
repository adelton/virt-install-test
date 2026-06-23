
def xcontains($element):
	. as $input
	| $element | to_entries | map($input[.key] == .value) | all
;

def random_select($count; $at_least_once):
	if $count <= 0 or length <= 0 then []
	else
		. as $in
		| reduce ($at_least_once | keys[]) as $k ($in;
			. as $iin
			| $at_least_once[$k]
			| until(length < 1 or (.[0] as $kk | any($iin[] | select(xcontains({ $k: $kk })))); .[1:])
			| . as $sel
			| if $sel | length > 0
				then [ $iin[] | select(xcontains({ $k: $sel[0] })) ]
				else $iin
				end
		)
		| .[ now * 1000000 % length ] as $row
		| [ $row,
			($in - [ $row ]
			| random_select($count - 1;
				reduce ($row | to_entries[]) as $e ($at_least_once;
					if .[$e.key] then .[$e.key] -= [ $e.value ] end)
				| del(..|select(. == []))
				)
			)[]
		]
	end
;

.["virt-install"]
| ( .[".exclude"] // [] ) as $exclude
| ( .[".count"] // ([ .[] | select(arrays), select(objects) | length ] | max * 2) ) as $count

| [ to_entries | map(select(.key | startswith(".") | not)) | from_entries ]
| until (([ .[][] | select(type == "array" or type == "object") ] | length) < 1;
	[ .[] |

		[ to_entries[]
			| select((.value | type) == "object" or (.value | type) == "array") ][0] as $i
		| if ($i.value | type) == "object"
			then . + ( $i.value | keys[] | { ($i.key): . } + $i.value[.] )
			elif ($i.value | type) == "array"
			then . + { ($i.key): ($i.value[]) }
		end
	]
)

| map(select(. as $in | any($exclude[] as $e | $in | xcontains($e)) | not))

| (reduce ( [ .[] | to_entries[] ] | unique[] ) as $i ({};
	(.[ $i.key ] | (now * 1000000 % (length + 1))) as $random_at
		| .[ $i.key ] = .[ $i.key ][0:$random_at] + [ $i.value ] + .[ $i.key ][$random_at:]
	)) as $at_least_once

| random_select($count; $at_least_once)

# order keys in object for better workflow run display
| map(. as $in | pick(.name, .arch, .["runs-on"], .boot, .["second-machine"]) + $in)

| sort_by(.name, .arch, .["runs-on"], .boot, .["second-machine"])

