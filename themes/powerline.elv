use re

fn -prompt-color [ color type ]{
  if (eq $color $nil) {
    if (eq $type fg) {
      put color15
    } else {
      put color0
    }
  } elif ?(== $color > /dev/null) {
    put 'color'$color
  } else {
    put $color
  }
}

fn -prompt-styled [ msg fg bg ]{
  styled-segment $msg &fg-color=$fg &bg-color=$bg
}

prompt-config = [
  &prefix=' '
  &suffix=' '
  &chain=''
  &cont=''
  &branch=''
  &ahead=''
  &behind=''
  &staged=''
  &dirty='✎'
  &untracked=''
]

prompt-segments = [
  [ &fg=254 &bg=166 &msg=[]{
    re:replace '\..*' '' (hostname)
    # hostname
  } ]

  [ &fg=15 &bg=28 &msg=[]{
    ppid = (ps -o ppid= $pid | awk '{ print $1 }')
    basename -- (ps -o cmd= $ppid | awk '{ print $1 }')
    # parent
  } ]

  [ &fg=15 &bg=31 &msg=[]{
    path = (re:replace '(\.?[^/]{3})[^/]*/' '${1}/' (tilde-abbr $pwd))
    re:replace '/' ' '$prompt-config[cont]' ' $path
    # cwd
  } ]

  [ &fg=226 &bg=12 &cond=[]{
    not-eq $E:VIRTUAL_ENV ''
  } &msg=[]{
    put ''(re:replace '\/.*\/' '' $E:VIRTUAL_ENV)
    # virtualenv
  } ]

  [ &fg=15 &bg=202 &cond=[]{
    put ?(direnv status | grep 'Loaded RC' > /dev/null)
  } &msg=[]{
    put ''
  } ]

  [ &state=[state]{
    bg = (-prompt-color $nil bg)
    put [
      &output=(-prompt-styled $prompt-config[chain]"\n" $state[last-bg] $bg)
      &state=[ &first=$true &last-fg=(-prompt-color $nil fg) &last-bg=$bg ]
    ]
    # newline
  } ]

  [ &fg=250 &bg=238 &msg=[]{
    date +%H:%M:%S
    # time
  } ]

  [ &fg=250 &bg=240 &msg=[]{
    whoami
    # username
  } ]

  [ &lambda=[]{
    if (eq (id -u) 0) {
      put [ &fg=15 &bg=161 &msg=[]{ put '' } ]
    } else {
      put [ &fg=15 &bg=(+ (% $pid 216) 16) &msg=[]{ put '' } ]
    }
    # arrow
  } ]

  [ &state=[state]{
    put [
      &output=(-prompt-styled $prompt-config[chain]' ' \
        $state[last-bg] (-prompt-color $nil bg))
      &state=$state
    ]
    # end
  } ]
]

fn -prompt-build []{
  state = [
    &first=$true
    &last-fg=(-prompt-color $nil fg)
    &last-bg=(-prompt-color $nil bg)
  ]
  for segs $prompt-segments {
    if (has-key $segs lambda) {
      segs = ($segs[lambda])
    }
    if (not-eq (kind-of $segs) list) {
      segs = [ $segs ]
    }
    for seg $segs {
      if (has-key $seg state) {
        out = ($seg[state] $state)
        state = $out[state]
        put $out[output]
        continue
      }
      if (and (has-key $seg cond) (not ($seg[cond]))) {
        continue
      }
      fg = (-prompt-color $seg[fg] fg)
      bg = (-prompt-color $seg[bg] bg)
      if (not $state[first]) {
        if (eq $state[last-bg] $bg) {
          put (-prompt-styled $prompt-config[cont] $state[last-fg] $bg)
        } else {
          put (-prompt-styled $prompt-config[chain] $state[last-bg] $bg)
        }
      }
      put (-prompt-styled $prompt-config[prefix] $fg $bg)
      put (-prompt-styled ($seg[msg]) $fg $bg)
      put (-prompt-styled $prompt-config[suffix] $fg $bg)
      state = [ &first=$false &last-fg=$fg &last-bg=$bg ]
    }
  }
}

edit:prompt = $-prompt-build~
edit:rprompt = []{}
