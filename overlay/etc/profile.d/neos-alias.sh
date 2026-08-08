export PATH=/usr/sbin:/usr/bin:/sbin:/bin
shopt -s expand_aliases
for _f in /usr/bin/neos-* /usr/bin/neolibs /usr/bin/pkg; do
  [ -x "$_f" ] && alias "$(basename "$_f")=/usr/bin/bash $_f"
done
unset _f
