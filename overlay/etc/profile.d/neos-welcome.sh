# neos-welcome — show the NeoOS landing banner on interactive logins.
# Fires once per session (interactive shell on a tty) so every new login feels alive.
if [[ $- == *i* && -t 1 && -z "${NEOS_WELCOME_SHOWN:-}" ]]; then
  neos-welcome
  NEOS_WELCOME_SHOWN=1; export NEOS_WELCOME_SHOWN
fi
