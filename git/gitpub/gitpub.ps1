<#
.SYNOPSIS
    gitpub
#>
gh repo list Michaelunkai --limit 5000 --json nameWithOwner -q '.[].nameWithOwner' | % { gh repo edit $_ --visibility public --accept-visibility-change-consequences }; gh repo list Michaelunkai --limit 5000 --json visibility -q '[.[] | .visibility] | group_by(.) | map({visibility: .[0], count: length})'
