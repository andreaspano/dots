# mutolo — jump into the mutolo box with its terminal profile applied for
# the duration of the session, then switch back to ernesto on return.
#
# Relies on fun-switch.sh's `switch` (present by the time this runs
# interactively, since bashrc sources every fun-*.sh before handing control
# to the prompt). ssh is blocking, so the restore below always runs once the
# session ends, however it ends.
#
# 192.168.1.1 is the ~/.ssh/config alias for mutolo (HostName mutolo, User
# andrea) — using it here so the configured user/host actually gets picked up.

mutolo() {
  switch mutolo
  ssh 192.168.1.1
  switch ernesto
}
