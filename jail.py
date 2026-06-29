import os
from ranger.core.tab import Tab

# Only jail when launched via the `rgr` shell function (fun-rgr.sh), which
# sets this var. Plain `ranger` runs are left completely untouched.
JAIL_ROOT = os.environ.get('RANGER_JAIL_ROOT')
if JAIL_ROOT:
    JAIL_ROOT = os.path.realpath(JAIL_ROOT)
    _orig_enter_dir = Tab.enter_dir

    # Tab.enter_dir is the single choke point every navigation action goes
    # through (h/left/backspace, :cd, bookmarks, gh, traverse), so patching
    # it here covers all of them instead of remapping each key individually.
    def _jailed_enter_dir(self, path, history=True):
        if path is None:
            return _orig_enter_dir(self, path, history=history)
        # Mirror ranger's own path resolution so "candidate" matches exactly
        # where the unpatched method would actually land.
        candidate = os.path.realpath(
            os.path.normpath(os.path.join(self.path, os.path.expanduser(str(path))))
        )
        if candidate != JAIL_ROOT and not candidate.startswith(JAIL_ROOT + os.sep):
            if os.path.realpath(self.path) == JAIL_ROOT:
                # Already at the boundary: refuse outright instead of moving.
                self.fm.notify("Can't go above " + JAIL_ROOT, bad=False)
                return False
            # Overshot from deeper inside (e.g. absolute path or multiple
            # "../../.."): clamp back to the root rather than refusing.
            path = JAIL_ROOT
        result = _orig_enter_dir(self, path, history=history)
        # Tab.pathway is what both the parent-directory column and the
        # titlebar breadcrumbs read from (via at_level() and directly,
        # respectively), so trimming everything above JAIL_ROOT out of it
        # hides those ancestors from view, not just from navigation.
        self.pathway = tuple(
            p for p in self.pathway
            if os.path.realpath(p.path) == JAIL_ROOT
            or os.path.realpath(p.path).startswith(JAIL_ROOT + os.sep)
        )
        return result

    Tab.enter_dir = _jailed_enter_dir
